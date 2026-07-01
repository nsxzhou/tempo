import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../database/database.dart' as db;
import '../../tasks/domain/task.dart';
import '../domain/stats_models.dart';

class StatsRepository {
  StatsRepository(this._database);

  final db.AppDatabase _database;

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
  StatsSnapshot computeSnapshot(List<Task> tasks, int days) {
    final active = tasks.where((t) => !t.isCompleted).toList();
    final now = DateTime.now();
    final windowStart = _dateOnly(now).subtract(Duration(days: days - 1));
    final windowEnd = _dateOnly(now).add(const Duration(days: 1));

    final windowTasks = tasks.where((t) {
      final created = _dateOnly(t.createdAt);
      return !created.isBefore(windowStart) && created.isBefore(windowEnd);
    }).toList();

    var overdue = 0;
    var weekDue = 0;
    for (final task in active) {
      final due = task.dueDate;
      if (due == null) continue;
      if (isTaskOverdue(
        dueDate: due,
        isAllDay: task.isAllDay,
        isCompleted: task.isCompleted,
        now: now,
      )) {
        overdue++;
      }
      if (isDueInWeekRange(due, now)) {
        weekDue++;
      }
    }

    final priorityCounts = <TaskPriority, int>{
      TaskPriority.p0: 0,
      TaskPriority.p1: 0,
      TaskPriority.p2: 0,
      TaskPriority.p3: 0,
    };
    for (final task in active) {
      if (task.priority == TaskPriority.none) continue;
      priorityCounts[task.priority] = (priorityCounts[task.priority] ?? 0) + 1;
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

    var work = 0;
    var life = 0;
    var untagged = 0;
    for (final task in active) {
      switch (task.tag) {
        case AppConstants.tagWork:
          work++;
        case AppConstants.tagLife:
          life++;
        default:
          untagged++;
      }
    }

    final categorySlices = <CategorySlice>[
      if (work > 0) CategorySlice(id: 'work', label: '工作', count: work),
      if (life > 0) CategorySlice(id: 'life', label: '生活', count: life),
      if (untagged > 0)
        CategorySlice(id: 'untagged', label: '未分类', count: untagged),
    ];

    final completedInWindow = windowTasks.where((t) => t.isCompleted).length;
    final completedInPeriod = tasks.where((t) {
      final completedAt = t.completedAt;
      if (completedAt == null) return false;
      final completedDay = _dateOnly(completedAt);
      return !completedDay.isBefore(windowStart) &&
          completedDay.isBefore(windowEnd);
    }).length;

    return StatsSnapshot(
      health: StatsHealth(
        pending: active.length,
        overdue: overdue,
        weekDue: weekDue,
        completedInPeriod: completedInPeriod,
      ),
      prioritySlices: prioritySlices,
      categorySlices: categorySlices,
      completionRate: CompletionRate(
        completed: completedInWindow,
        total: windowTasks.length,
      ),
    );
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
      final day = _dateOnly(completedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    // 重复任务：按 task_completions.completed_at 桶
    for (final row in completionRows) {
      final day = _dateOnly(row.completedAt);
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
    final start = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    final end = _dateOnly(DateTime.now()).add(const Duration(days: 1));
    return (start: start, end: end);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
