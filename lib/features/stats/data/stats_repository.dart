import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/task_filter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../database/database.dart' as db;
import '../../tasks/domain/recurrence_engine.dart';
import '../../tasks/domain/recurrence_models.dart';
import '../../tasks/domain/task.dart';
import '../domain/stats_models.dart';

class StatsRepository {
  StatsRepository(this._database);

  final db.AppDatabase _database;
  static const _engine = RecurrenceEngine();

  /// Drift 监听 + 按日聚合（补零空日）。
  ///
  /// 入桶来源 union：
  /// - 单次任务（recurrence_rule IS NULL）：tasks.completed_at
  /// - 重复任务：task_completions.completed_at
  /// 重复任务从不写 tasks.completed_at，避免双计。
  Stream<List<DailyCompletion>> watchDailyCompletions(int days) {
    final range = _dateRange(days);
    final tasksStream = _database.watchCompletedTasksInRange(
      range.start,
      range.end,
    );
    final completionsStream = _database.watchTaskCompletionsInRange(
      range.start,
      range.end,
    );
    return _combineLatest(tasksStream, completionsStream).map(
      (pair) => _aggregateDailyUnion(pair.$1, pair.$2, range.start, days),
    );
  }

  /// 内存聚合：优先级 / 分类 / 完成率。
  ///
  /// 重复任务在窗口内按 occurrence 展开；单次任务保持 series 级语义。
  StatsSnapshot computeSnapshot({
    required List<Task> tasks,
    required List<TaskCompletion> completions,
    required List<RecurrenceException> exceptions,
    required int days,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = calendarDay(current);
    final windowStart = today.subtract(Duration(days: days - 1));

    var pending = 0;
    var overdue = 0;
    var weekDue = 0;
    var completedInPeriod = 0;
    var scheduledInWindow = 0;
    var completedInWindow = 0;

    final priorityCounts = <TaskPriority, int>{
      TaskPriority.p0: 0,
      TaskPriority.p1: 0,
      TaskPriority.p2: 0,
      TaskPriority.p3: 0,
    };
    var work = 0;
    var life = 0;
    var untagged = 0;

    for (final task in tasks) {
      if (task.isRecurring) {
        final taskCompletions = completions.forTask(task.id, (c) => c.taskId);
        final taskExceptions = exceptions.forTask(task.id, (e) => e.taskId);
        final occs = _engine.expandOccurrences(
          task,
          from: windowStart,
          to: today,
          completions: taskCompletions,
          exceptions: taskExceptions,
          now: current,
        );

        for (final occ in occs) {
          if (occ.occurrenceDate.isAfter(today)) continue;
          scheduledInWindow++;

          switch (occ.state) {
            case OccurrenceState.completed:
              completedInPeriod++;
              completedInWindow++;
            case OccurrenceState.missed:
              overdue++;
              _incrementPriorityAndCategory(
                task,
                priorityCounts,
                onWork: () => work++,
                onLife: () => life++,
                onUntagged: () => untagged++,
              );
            case OccurrenceState.pending:
              pending++;
              _incrementPriorityAndCategory(
                task,
                priorityCounts,
                onWork: () => work++,
                onLife: () => life++,
                onUntagged: () => untagged++,
              );
              final due = occ.effectiveDue;
              if (due != null && isDueInWeekRange(due, current)) {
                weekDue++;
              }
          }
        }
      } else {
        final created = calendarDay(task.createdAt);
        final createdInWindow =
            !created.isBefore(windowStart) && !created.isAfter(today);

        if (!task.isCompleted) {
          pending++;
          _incrementPriorityAndCategory(
            task,
            priorityCounts,
            onWork: () => work++,
            onLife: () => life++,
            onUntagged: () => untagged++,
          );
          final due = task.dueDate;
          if (due != null) {
            if (isTaskOverdue(
              dueDate: due,
              isAllDay: task.isAllDay,
              isCompleted: false,
              now: current,
            )) {
              overdue++;
            }
            if (isDueInWeekRange(due, current)) {
              weekDue++;
            }
          }
        }

        if (createdInWindow) {
          scheduledInWindow++;
          if (task.isCompleted) {
            completedInWindow++;
          }
        }

        final completedAt = task.completedAt;
        if (completedAt != null) {
          final completedDay = calendarDay(completedAt);
          if (!completedDay.isBefore(windowStart) &&
              !completedDay.isAfter(today)) {
            completedInPeriod++;
          }
        }
      }
    }

    final prioritySlices = priorityCounts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PrioritySlice(
            priority: e.key,
            count: e.value,
            label: e.key.label ?? e.key.name.toUpperCase(),
          ),
        )
        .toList();

    final categorySlices = <CategorySlice>[
      if (work > 0) CategorySlice(id: 'work', label: '工作', count: work),
      if (life > 0) CategorySlice(id: 'life', label: '生活', count: life),
      if (untagged > 0)
        CategorySlice(id: 'untagged', label: '未分类', count: untagged),
    ];

    return StatsSnapshot(
      health: StatsHealth(
        pending: pending,
        overdue: overdue,
        weekDue: weekDue,
        completedInPeriod: completedInPeriod,
      ),
      prioritySlices: prioritySlices,
      categorySlices: categorySlices,
      completionRate: CompletionRate(
        completed: completedInWindow,
        total: scheduledInWindow,
      ),
    );
  }

  void _incrementPriorityAndCategory(
    Task task,
    Map<TaskPriority, int> priorityCounts, {
    required void Function() onWork,
    required void Function() onLife,
    required void Function() onUntagged,
  }) {
    if (task.priority != TaskPriority.none) {
      priorityCounts[task.priority] = (priorityCounts[task.priority] ?? 0) + 1;
    }
    switch (task.tag) {
      case AppConstants.tagWork:
        onWork();
      case AppConstants.tagLife:
        onLife();
      default:
        onUntagged();
    }
  }

  List<DailyCompletion> _aggregateDailyUnion(
    List<db.Task> taskRows,
    List<db.TaskCompletion> completionRows,
    DateTime startDay,
    int days,
  ) {
    final counts = <DateTime, int>{};
    // 单次任务：按 tasks.completed_at 桶
    for (final row in taskRows) {
      // 重复任务的完成不应走 tasks.completed_at（正常路径下不会写），
      // 但容错过滤：若 history 残留了重复任务的 series 级完成，跳过避免双计。
      if (row.recurrenceRule != null && row.recurrenceRule!.isNotEmpty) {
        continue;
      }
      final completedAt = row.completedAt;
      if (completedAt == null) continue;
      final day = calendarDay(completedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    // 重复任务：按 task_completions.completed_at 桶
    for (final row in completionRows) {
      final day = calendarDay(row.completedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return List.generate(days, (i) {
      final day = startDay.add(Duration(days: i));
      return DailyCompletion(date: day, count: counts[day] ?? 0);
    });
  }

  /// 合并两条 Drift Stream，任一更新都重发最新组合。
  ///
  /// Drift 不依赖 rxdart；这里手写 broadcast controller 实现等价 combineLatest。
  Stream<(List<db.Task>, List<db.TaskCompletion>)> _combineLatest(
    Stream<List<db.Task>> a,
    Stream<List<db.TaskCompletion>> b,
  ) {
    List<db.Task>? lastA;
    List<db.TaskCompletion>? lastB;
    final controller = StreamController<
      (List<db.Task>, List<db.TaskCompletion>)
    >.broadcast();
    void emit() {
      if (lastA != null && lastB != null) {
        controller.add((lastA!, lastB!));
      }
    }

    final subA = a.listen(
      (v) {
        lastA = v;
        emit();
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    final subB = b.listen(
      (v) {
        lastB = v;
        emit();
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };
    return controller.stream;
  }

  ({DateTime start, DateTime end}) _dateRange(int days) {
    final start = calendarDay(DateTime.now()).subtract(Duration(days: days - 1));
    final end = calendarDay(DateTime.now()).add(const Duration(days: 1));
    return (start: start, end: end);
  }
}
