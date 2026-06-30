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
        final next = _engine.nextOccurrence(
          task,
          exceptions: exceptions.where((e) => e.taskId == task.id).toList(),
          completions: completions.where((c) => c.taskId == task.id).toList(),
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
          exceptions: exceptions.where((e) => e.taskId == task.id).toList(),
          completions: completions.where((c) => c.taskId == task.id).toList(),
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
        completions: completions.where((c) => c.taskId == task.id).toList(),
        exceptions: exceptions.where((e) => e.taskId == task.id).toList(),
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
