import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/domain/task_counts.dart';
import 'package:tempo/features/tasks/domain/task_list_builder.dart';
import 'package:tempo/features/tasks/presentation/tasks_filter.dart';

void main() {
  Task endedDisplayTask() {
    final now = DateTime.now();
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final task = Task(
      id: 'ended',
      listId: 'list',
      title: '已结束系列',
      dueDate: end,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      recurrenceEnd: end,
      createdAt: end.subtract(const Duration(days: 3)),
      updatedAt: end,
    );
    return const TaskListBuilder()
        .buildListViews(tasks: [task], now: now)
        .single
        .displayTask;
  }

  test('ended recurring series is grouped as completed only in all scope', () {
    final ended = endedDisplayTask();

    for (final scope in [
      TaskScope.pending,
      TaskScope.overdue,
      TaskScope.week,
    ]) {
      final snapshot = buildTaskFilterSnapshot(
        allTasks: [ended],
        scope: scope,
        searchQuery: '',
      );
      expect(snapshot.groups.active, isEmpty, reason: '$scope active');
      expect(snapshot.groups.completed, isEmpty, reason: '$scope completed');
    }

    final all = buildTaskFilterSnapshot(
      allTasks: [ended],
      scope: TaskScope.all,
      searchQuery: '',
    );
    expect(all.groups.active, isEmpty);
    expect(all.groups.completed, hasLength(1));
  });

  test(
    'ended recurring series contributes to list completed count, not occurrence progress',
    () {
      final ended = endedDisplayTask();
      final counts = TaskCounts.from([ended]);

      expect(counts.completed, 1);
      expect(counts.overdue, 0);
      expect(counts.pending, 0);
    },
  );
}
