import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/domain/task_list_builder.dart';

void main() {
  const builder = TaskListBuilder();

  Task recurringTask({required String id, DateTime? dueDate}) {
    return Task(
      id: id,
      listId: 'list',
      title: 'Daily habit',
      dueDate: dueDate,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
  }

  test('buildListViews returns next occurrence when dueDate is set', () {
    final task = recurringTask(id: 'r1', dueDate: DateTime(2026, 6, 1));
    final views = builder.buildListViews(
      tasks: [task],
      now: DateTime(2026, 6, 15),
    );

    expect(views, hasLength(1));
    expect(views.first.displayTask.dueDate, isNotNull);
    expect(views.first.displayTask.isCompleted, isFalse);
  });

  test('buildListViews skips recurring task without dueDate', () {
    final task = recurringTask(id: 'r2', dueDate: null);
    final views = builder.buildListViews(
      tasks: [task],
      now: DateTime(2026, 6, 15),
    );

    expect(views, isEmpty);
  });

  test('buildCalendarIndex expands around centerDate not today', () {
    final task = recurringTask(id: 'r3', dueDate: DateTime(2026, 12, 1));
    final index = builder.buildCalendarIndex(
      tasks: [task],
      centerDate: DateTime(2026, 12, 15),
      now: DateTime(2026, 6, 1),
    );

    expect(index.containsKey(DateTime(2026, 12, 1)), isTrue);
    expect(index.containsKey(DateTime(2026, 12, 15)), isTrue);
    expect(index.containsKey(DateTime(2026, 6, 1)), isFalse);
  });

  test('buildListViews includes ended recurring series', () {
    final now = DateTime(2026, 6, 30);
    final task = Task(
      id: 'ended',
      listId: 'list',
      title: 'Ended habit',
      dueDate: DateTime(2026, 6, 1),
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      recurrenceEnd: DateTime(2026, 6, 29),
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 29),
    );
    final views = builder.buildListViews(tasks: [task], now: now);

    expect(views, hasLength(1));
    expect(views.first.isSeriesEnded, isTrue);
    expect(views.first.displayTask.dueDate, isNull);
    expect(task.isRecurrenceEnded(now), isTrue);
  });
}
