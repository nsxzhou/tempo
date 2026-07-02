import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/recurrence_engine.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  const engine = RecurrenceEngine();

  Task dailyTask({
    String id = 't1',
    DateTime? due,
    String rule = 'FREQ=DAILY;INTERVAL=1',
    int? count,
    DateTime? end,
  }) {
    return Task(
      id: id,
      listId: 'list',
      title: '锻炼',
      dueDate: due ?? DateTime(2026, 6, 1, 20),
      recurrenceRule: rule,
      recurrenceCount: count,
      recurrenceEnd: end,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
  }

  test('expandOccurrences daily for 5 days', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final occs = engine.expandOccurrences(
      task,
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 5),
      now: DateTime(2026, 6, 1),
    );
    expect(occs.length, 5);
    expect(occs.first.effectiveDue?.hour, 20);
  });

  test('weekly BYDAY expands Mon Wed Fri only', () {
    final task = dailyTask(
      due: DateTime(2026, 6, 2), // Monday
      rule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR',
    );
    final occs = engine.expandOccurrences(
      task,
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 14),
      now: DateTime(2026, 6, 1),
    );
    expect(occs.map((o) => o.occurrenceDate.weekday).toSet(), {
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    });
  });

  test('completion marks completed, past without completion is missed', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final completions = [
      TaskCompletion(
        taskId: task.id,
        occurrenceDate: DateTime(2026, 6, 1),
        completedAt: DateTime(2026, 6, 1, 20, 30),
      ),
    ];
    final occs = engine.expandOccurrences(
      task,
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 3),
      completions: completions,
      now: DateTime(2026, 6, 3),
    );
    expect(occs[0].state, OccurrenceState.completed);
    expect(occs[1].state, OccurrenceState.missed);
    expect(occs[2].state, OccurrenceState.pending);
  });

  test('streak counts consecutive completed from today backwards', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final completions = [
      for (var d = 1; d <= 3; d++)
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 6, d),
          completedAt: DateTime(2026, 6, d, 21),
        ),
    ];
    final streak = engine.computeStreak(
      task,
      completions: completions,
      now: DateTime(2026, 6, 3),
    );
    expect(streak.current, 3);
    expect(streak.completedCount, 3);
  });

  test('backfill on later day still counts occurrence_date for streak', () {
    final task = dailyTask(
      due: DateTime(2026, 6, 30, 20),
      rule: 'FREQ=DAILY;INTERVAL=1',
      count: 5,
    );
    final completions = [
      TaskCompletion(
        taskId: task.id,
        occurrenceDate: DateTime(2026, 6, 30),
        completedAt: DateTime(2026, 7, 1, 9),
      ),
      TaskCompletion(
        taskId: task.id,
        occurrenceDate: DateTime(2026, 7, 1),
        completedAt: DateTime(2026, 7, 1, 10),
      ),
    ];
    final streak = engine.computeStreak(
      task,
      completions: completions,
      now: DateTime(2026, 7, 1, 12),
    );
    expect(streak.current, 2);
    expect(streak.seriesCompleted, 2);
    expect(streak.seriesProgressLabel, '2/5 次');
    expect(streak.hasSeriesCap, isTrue);
  });

  test('unlimited series hides series progress label', () {
    final task = dailyTask(due: DateTime(2026, 7, 1, 20));
    final streak = engine.computeStreak(
      task,
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 7, 1),
          completedAt: DateTime(2026, 7, 1, 11),
        ),
      ],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(streak.hasSeriesCap, isFalse);
    expect(streak.seriesProgressLabel, isNull);
    expect(streak.current, 1);
  });

  test('nextOccurrence returns first pending', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final next = engine.nextOccurrence(
      task,
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 6, 1),
          completedAt: DateTime(2026, 6, 1, 21),
        ),
      ],
      now: DateTime(2026, 6, 1, 22),
    );
    expect(next?.occurrenceDate, DateTime(2026, 6, 2));
  });

  test('nextCompletableOccurrence returns today when pending', () {
    final task = dailyTask(due: DateTime(2026, 7, 1, 20));
    final next = engine.nextCompletableOccurrence(
      task,
      now: DateTime(2026, 7, 1, 12),
    );
    expect(next?.occurrenceDate, DateTime(2026, 7, 1));
    expect(next?.state, OccurrenceState.pending);
  });

  test('nextCompletableOccurrence does not return tomorrow after today done', () {
    final task = dailyTask(due: DateTime(2026, 7, 1, 20));
    final next = engine.nextCompletableOccurrence(
      task,
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 7, 1),
          completedAt: DateTime(2026, 7, 1, 11),
        ),
      ],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(next, isNull);
  });

  test('nextCompletableOccurrence returns earliest missed day for backfill', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final next = engine.nextCompletableOccurrence(
      task,
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 6, 30),
          completedAt: DateTime(2026, 7, 1, 9),
        ),
      ],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(next?.occurrenceDate, DateTime(2026, 7, 1));
    expect(next?.state, OccurrenceState.pending);
  });

  test('nextCompletableOccurrence prefers today over past missed', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final next = engine.nextCompletableOccurrence(
      task,
      now: DateTime(2026, 7, 1, 12),
    );
    expect(next?.occurrenceDate, DateTime(2026, 7, 1));
  });

  test('RecurrenceConfig toRRule roundtrip', () {
    const config = RecurrenceConfig(
      interval: 2,
      unit: RecurrenceUnit.week,
      weekdays: {DateTime.monday, DateTime.wednesday},
    );
    final parsed = RecurrenceConfig.fromRRule(config.toRRule());
    expect(parsed?.interval, 2);
    expect(parsed?.unit, RecurrenceUnit.week);
    expect(parsed?.weekdays, {DateTime.monday, DateTime.wednesday});
  });
}
