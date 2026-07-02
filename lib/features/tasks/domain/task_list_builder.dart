import '../../../core/extensions/task_filter.dart';
import 'recurrence_engine.dart';
import 'recurrence_models.dart';
import 'task.dart';

/// 将原始 task 列表转为 UI 展示列表（重复任务 → 下一次 occurrence）
class TaskListBuilder {
  const TaskListBuilder({RecurrenceEngine? engine})
    : _engine = engine ?? const RecurrenceEngine();

  final RecurrenceEngine _engine;

  List<TaskOccurrenceView> buildListViews({
    required List<Task> tasks,
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
  }) {
    final views = <TaskOccurrenceView>[];
    final current = now ?? DateTime.now();
    for (final task in tasks) {
      if (task.isRecurring) {
        final taskExceptions = exceptions.forTask(task.id, (e) => e.taskId);
        final taskCompletions = completions.forTask(task.id, (c) => c.taskId);
        final next = _engine.nextCompletableOccurrence(
          task,
          exceptions: taskExceptions,
          completions: taskCompletions,
          now: current,
        );
        if (next != null) {
          views.add(TaskOccurrenceView(seriesTask: task, occurrence: next));
        } else if (task.isRecurrenceEnded(current)) {
          views.add(
            TaskOccurrenceView(
              seriesTask: task,
              occurrence: TaskOccurrence(
                seriesTaskId: task.id,
                occurrenceDate: RecurrenceEngine.calendarDay(
                  task.recurrenceEnd!,
                ),
                effectiveDue: null,
                title: task.title,
              ),
              isSeriesEnded: true,
            ),
          );
        } else {
          // 今日已打完卡：在「全部」列表的已完成区展示，便于发现重复系列并删除。
          final todayView = resolveOccurrenceView(
            task: task,
            contextDate: current,
            completions: taskCompletions,
            exceptions: taskExceptions,
            now: current,
          );
          if (todayView != null &&
              todayView.occurrence.state == OccurrenceState.completed) {
            views.add(todayView);
          }
        }
      } else {
        views.add(
          TaskOccurrenceView(
            seriesTask: task,
            occurrence: TaskOccurrence(
              seriesTaskId: task.id,
              occurrenceDate: task.dueDate != null
                  ? RecurrenceEngine.calendarDay(task.dueDate!)
                  : RecurrenceEngine.calendarDay(now ?? DateTime.now()),
              effectiveDue: task.dueDate,
              title: task.title,
              state: task.isCompleted
                  ? OccurrenceState.completed
                  : OccurrenceState.pending,
            ),
          ),
        );
      }
    }
    return views;
  }

  Map<DateTime, List<CalendarTaskEntry>> buildCalendarIndex({
    required List<Task> tasks,
    required DateTime centerDate,
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
    int monthPadding = 3,
  }) {
    final from = DateTime(centerDate.year, centerDate.month - monthPadding, 1);
    final to = DateTime(centerDate.year, centerDate.month + monthPadding + 1, 0);
    final index = <DateTime, List<CalendarTaskEntry>>{};

    for (final task in tasks) {
      if (task.isRecurring) {
        final occs = _engine.expandOccurrences(
          task,
          from: from,
          to: to,
          exceptions: exceptions.forTask(task.id, (e) => e.taskId),
          completions: completions.forTask(task.id, (c) => c.taskId),
          now: now,
        );
        for (final occ in occs) {
          final day = occ.calendarDay;
          index.putIfAbsent(day, () => []).add(
            CalendarTaskEntry(
              task: task,
              occurrence: occ,
              isRecurring: true,
            ),
          );
        }
      } else if (task.dueDate != null) {
        final day = RecurrenceEngine.calendarDay(task.dueDate!);
        if (!day.isBefore(from) && !day.isAfter(to)) {
          index.putIfAbsent(day, () => []).add(
            CalendarTaskEntry(
              task: task,
              occurrence: TaskOccurrence(
                seriesTaskId: task.id,
                occurrenceDate: day,
                effectiveDue: task.dueDate,
                title: task.title,
                state: task.isCompleted
                    ? OccurrenceState.completed
                    : (day.isBefore(RecurrenceEngine.calendarDay(now ?? DateTime.now()))
                        ? OccurrenceState.missed
                        : OccurrenceState.pending),
              ),
              isRecurring: false,
            ),
          );
        }
      }
    }
    return index;
  }

  /// 按日历上下文日解析重复任务的 occurrence（用于详情页 `?date=` 入口）。
  ///
  /// 若 [contextDate] 当天无排期则返回 null。
  TaskOccurrenceView? resolveOccurrenceView({
    required Task task,
    required DateTime contextDate,
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
  }) {
    if (!task.isRecurring) return null;

    final day = RecurrenceEngine.calendarDay(contextDate);
    final occs = _engine.expandOccurrences(
      task,
      from: day,
      to: day,
      exceptions: exceptions.forTask(task.id, (e) => e.taskId),
      completions: completions.forTask(task.id, (c) => c.taskId),
      now: now,
    );
    if (occs.isEmpty) return null;
    return TaskOccurrenceView(seriesTask: task, occurrence: occs.first);
  }

  /// 展开有次数上限的重复系列的全部 occurrence（详情时间轴 + 进度共用）。
  ///
  /// 无 `recurrenceCount` 上限时返回空列表（无限重复无系列时间轴）。
  List<TaskOccurrence> buildSeriesOccurrences({
    required Task task,
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
  }) {
    if (!task.isRecurring || task.dueDate == null) return const [];
    final count = task.recurrenceCount;
    if (count == null || count <= 0) return const [];

    final anchor = RecurrenceEngine.calendarDay(task.dueDate!);
    return _engine.expandOccurrences(
      task,
      from: anchor,
      to: anchor.add(const Duration(days: 365 * 5)),
      exceptions: exceptions.forTask(task.id, (e) => e.taskId),
      completions: completions.forTask(task.id, (c) => c.taskId),
      now: now,
    );
  }

  Map<String, StreakInfo> buildStreakMap({
    required List<Task> tasks,
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
  }) {
    final map = <String, StreakInfo>{};
    for (final task in tasks.where((t) => t.isRecurring)) {
      map[task.id] = _engine.computeStreak(
        task,
        completions: completions.forTask(task.id, (c) => c.taskId),
        exceptions: exceptions.forTask(task.id, (e) => e.taskId),
        now: now,
      );
    }
    return map;
  }
}

/// 日历索引条目
class CalendarTaskEntry {
  const CalendarTaskEntry({
    required this.task,
    required this.occurrence,
    required this.isRecurring,
  });

  final Task task;
  final TaskOccurrence occurrence;
  final bool isRecurring;

  Task get displayTask => task.copyWith(
    dueDate: occurrence.effectiveDue,
    title: occurrence.title,
    isCompleted: occurrence.state == OccurrenceState.completed,
  );
}
