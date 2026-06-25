import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/database/database.dart' hide Task;
import 'package:tempo/features/stats/data/stats_repository.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late StatsRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.taskLists)
        .insert(
          TaskListsCompanion.insert(
            id: AppConstants.defaultListId,
            userId: 'user-1',
            name: AppConstants.defaultListName,
          ),
        );
    repository = StatsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTask({
    required String id,
    required DateTime createdAt,
    bool isCompleted = false,
    DateTime? completedAt,
    TaskPriority priority = TaskPriority.none,
    String? tag,
  }) async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            listId: AppConstants.defaultListId,
            title: 'Task $id',
            createdAt: Value(createdAt),
            updatedAt: Value(createdAt),
            isCompleted: Value(isCompleted),
            completedAt: Value(completedAt),
            priority: Value(priority.value),
            tag: Value(tag),
          ),
        );
  }

  test('watchDailyCompletions aggregates by completed_at day', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 15);
    final yesterday = today.subtract(const Duration(days: 1));

    await insertTask(
      id: '1',
      createdAt: yesterday,
      isCompleted: true,
      completedAt: yesterday,
    );
    await insertTask(
      id: '2',
      createdAt: today,
      isCompleted: true,
      completedAt: today,
    );
    await insertTask(
      id: '3',
      createdAt: today,
      isCompleted: true,
      completedAt: today,
    );

    final stream = repository.watchDailyCompletions(7);
    final first = await stream.first;

    expect(first, hasLength(7));
    expect(first.last.count, 2);
    expect(first[first.length - 2].count, 1);
  });

  test('computeSnapshot counts priority and categories for active tasks', () {
    final tasks = [
      Task(
        id: '1',
        listId: AppConstants.defaultListId,
        title: 'P0 work',
        priority: TaskPriority.p0,
        tag: AppConstants.tagWork,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: '2',
        listId: AppConstants.defaultListId,
        title: 'P1 life',
        priority: TaskPriority.p1,
        tag: AppConstants.tagLife,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: '3',
        listId: AppConstants.defaultListId,
        title: 'untagged',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: '4',
        listId: AppConstants.defaultListId,
        title: 'done',
        isCompleted: true,
        completedAt: DateTime.now(),
        priority: TaskPriority.p0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final snapshot = repository.computeSnapshot(tasks, 7);

    expect(snapshot.prioritySlices, hasLength(2));
    expect(snapshot.categorySlices, hasLength(3));
    expect(snapshot.completionRate.total, 4);
    expect(snapshot.completionRate.completed, 1);
  });
}
