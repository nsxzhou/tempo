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
    String? recurrenceRule,
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
            recurrenceRule: Value(recurrenceRule),
          ),
        );
  }

  Future<void> insertCompletion({
    required String taskId,
    required DateTime occurrenceDate,
    required DateTime completedAt,
  }) async {
    await db
        .into(db.taskCompletions)
        .insert(
          TaskCompletionsCompanion.insert(
            taskId: taskId,
            occurrenceDate: occurrenceDate,
            completedAt: Value(completedAt),
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

  test(
    'watchDailyCompletions unions single-task and recurring-task sources',
    () async {
      // 复刻用户 6/30→7/1 bug：单次任务用 tasks.completed_at 入桶，
      // 重复任务用 task_completions.completed_at 入桶，避免串日。
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 15);
      final yesterday = today.subtract(const Duration(days: 1));

      // 单次任务：今天完成
      await insertTask(
        id: 'single-1',
        createdAt: yesterday,
        isCompleted: true,
        completedAt: today,
      );

      // 重复任务：昨天打卡（occurrenceDate=昨天, completedAt=昨天 22:00）
      // 不应再写 tasks.completed_at
      await insertTask(
        id: 'recurring-1',
        createdAt: yesterday,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      );
      await insertCompletion(
        taskId: 'recurring-1',
        occurrenceDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        completedAt: yesterday,
      );

      final stream = repository.watchDailyCompletions(7);
      final first = await stream.first;

      expect(first, hasLength(7));
      // 昨天应只有 1 条（重复任务的打卡）
      expect(first[first.length - 2].count, 1);
      // 今天应只有 1 条（单次任务）
      expect(first.last.count, 1);
    },
  );

  test(
    'watchDailyCompletions skips stale series-level completed_at on recurring tasks',
    () async {
      // 历史脏数据：重复任务 series 的 is_completed=true + completed_at=今天
      // （来自旧的 detail-page bug）。新逻辑不应计入这条，避免双计。
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 15);
      final yesterday = today.subtract(const Duration(days: 1));

      await insertTask(
        id: 'dirty-recurring',
        createdAt: yesterday,
        isCompleted: true,
        completedAt: today,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      );
      // 正确的打卡记录在昨天
      await insertCompletion(
        taskId: 'dirty-recurring',
        occurrenceDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        completedAt: yesterday,
      );

      final stream = repository.watchDailyCompletions(7);
      final first = await stream.first;

      // 今天应该是 0（脏数据被过滤），昨天应该是 1（task_completions）
      expect(first.last.count, 0);
      expect(first[first.length - 2].count, 1);
    },
  );

  test('computeSnapshot counts priority and categories for active tasks', () {
    final now = DateTime.now();
    final tasks = [
      Task(
        id: '1',
        listId: AppConstants.defaultListId,
        title: 'P0 work',
        priority: TaskPriority.p0,
        tag: AppConstants.tagWork,
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '2',
        listId: AppConstants.defaultListId,
        title: 'P1 life',
        priority: TaskPriority.p1,
        tag: AppConstants.tagLife,
        dueDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '3',
        listId: AppConstants.defaultListId,
        title: 'untagged',
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '4',
        listId: AppConstants.defaultListId,
        title: 'done',
        isCompleted: true,
        completedAt: now,
        priority: TaskPriority.p0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final snapshot = repository.computeSnapshot(tasks, 7);

    expect(snapshot.health.pending, 3);
    expect(snapshot.health.overdue, 1);
    expect(snapshot.health.weekDue, 1);
    expect(snapshot.health.completedInPeriod, 1);
    expect(snapshot.prioritySlices, hasLength(2));
    expect(snapshot.categorySlices, hasLength(3));
    expect(snapshot.categorySlices.last.label, '未分类');
    expect(snapshot.completionRate.total, 4);
    expect(snapshot.completionRate.completed, 1);
  });
}
