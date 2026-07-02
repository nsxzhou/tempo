import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/domain/task_list_builder.dart';

void main() {
  const builder = TaskListBuilder();

  Task dailyTask({DateTime? due}) {
    return Task(
      id: 't1',
      listId: 'list',
      title: '锻炼',
      dueDate: due ?? DateTime(2026, 6, 1, 20),
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
  }

  test('resolveOccurrenceView returns historical missed occurrence', () {
    final task = dailyTask();
    final view = builder.resolveOccurrenceView(
      task: task,
      contextDate: DateTime(2026, 6, 30),
      now: DateTime(2026, 7, 1),
    );

    expect(view, isNotNull);
    expect(view!.occurrence.occurrenceDate, DateTime(2026, 6, 30));
    expect(view.occurrence.state, OccurrenceState.missed);
    expect(view.displayTask.isCompleted, isFalse);
  });

  test('resolveOccurrenceView returns completed state when completion exists', () {
    final task = dailyTask();
    final view = builder.resolveOccurrenceView(
      task: task,
      contextDate: DateTime(2026, 6, 30),
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 6, 30),
          completedAt: DateTime(2026, 7, 1, 9),
        ),
      ],
      now: DateTime(2026, 7, 1),
    );

    expect(view!.occurrence.state, OccurrenceState.completed);
    expect(view.displayTask.isCompleted, isTrue);
  });

  test('resolveOccurrenceView returns null when day is not scheduled', () {
    final task = dailyTask(
      due: DateTime(2026, 6, 2),
    ).copyWith(recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO');
    final view = builder.resolveOccurrenceView(
      task: task,
      contextDate: DateTime(2026, 6, 30), // Monday in June 2026 is 1,8,15,22,29
      now: DateTime(2026, 7, 1),
    );

    expect(view, isNull);
  });

  group('buildSeriesOccurrences', () {
    // 每 2 天一次、共 5 次：6/1, 6/3, 6/5, 6/7, 6/9
    Task cappedTask() {
      return Task(
        id: 'series',
        listId: 'list',
        title: '打卡',
        dueDate: DateTime(2026, 6, 1, 20),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=2;COUNT=5',
        recurrenceCount: 5,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
    }

    test('returns 5 occurrences with 3 completed', () {
      final task = cappedTask();
      final occs = builder.buildSeriesOccurrences(
        task: task,
        completions: [
          for (final d in [DateTime(2026, 6, 1), DateTime(2026, 6, 3), DateTime(2026, 6, 5)])
            TaskCompletion(
              taskId: task.id,
              occurrenceDate: d,
              completedAt: DateTime(2026, 6, 9, 9),
            ),
        ],
        now: DateTime(2026, 6, 9),
      );

      expect(occs.length, 5);
      final completed = occs
          .where((o) => o.state == OccurrenceState.completed)
          .length;
      expect(completed, 3);
    });

    test('returns empty for unlimited recurring task', () {
      final task = dailyTask(); // no recurrenceCount
      final occs = builder.buildSeriesOccurrences(
        task: task,
        now: DateTime(2026, 7, 1),
      );
      expect(occs, isEmpty);
    });
  });

  test('buildListViews shows today-completed recurring task for visibility', () {
    final task = dailyTask(due: DateTime(2026, 7, 1, 20));
    final views = builder.buildListViews(
      tasks: [task],
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 7, 1),
          completedAt: DateTime(2026, 7, 1, 11),
        ),
      ],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(views, hasLength(1));
    expect(views.single.displayTask.isCompleted, isTrue);
  });

  test('buildListViews shows unlimited task when today is still pending', () {
    final task = dailyTask(due: DateTime(2026, 7, 1, 20));
    final views = builder.buildListViews(
      tasks: [task],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(views, hasLength(1));
    expect(views.single.occurrence.occurrenceDate, DateTime(2026, 7, 1));
  });

  test('buildListViews shows earliest missed day for backfill', () {
    final task = dailyTask(due: DateTime(2026, 6, 1, 20));
    final views = builder.buildListViews(
      tasks: [task],
      completions: [
        TaskCompletion(
          taskId: task.id,
          occurrenceDate: DateTime(2026, 6, 30),
          completedAt: DateTime(2026, 7, 1, 9),
        ),
      ],
      now: DateTime(2026, 7, 1, 12),
    );
    expect(views, hasLength(1));
    expect(views.single.occurrence.occurrenceDate, DateTime(2026, 7, 1));
  });
}
