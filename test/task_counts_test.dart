import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/domain/task_counts.dart';

void main() {
  group('TaskCounts.from', () {
    test('aggregates all metrics in a single pass', () {
      final now = DateTime(2026, 6, 25, 12);
      final tasks = [
        Task(
          id: '1',
          listId: 'inbox',
          title: 'Pending today',
          dueDate: now,
          tag: AppConstants.tagWork,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: '2',
          listId: 'inbox',
          title: 'Overdue',
          dueDate: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: '3',
          listId: 'inbox',
          title: 'Done',
          isCompleted: true,
          tag: AppConstants.tagLife,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final counts = TaskCounts.from(tasks);
      expect(counts.total, 3);
      expect(counts.pending, 2);
      expect(counts.overdue, 1);
      expect(counts.work, 1);
      expect(counts.life, 1);
    });

    test('empty list returns zero counts', () {
      expect(TaskCounts.from([]), TaskCounts.empty);
    });
  });
}
