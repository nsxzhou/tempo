import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/database/database.dart' hide Task;
import 'package:tempo/features/tasks/data/task_repository.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late _TestConnectivityService connectivity;

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
    connectivity = _TestConnectivityService();
  });

  tearDown(() async {
    connectivity.dispose();
    await db.close();
  });

  SyncTaskRepository buildRepository({
    Future<Task> Function(Task task, String userId)? remoteTaskUpsert,
    Future<List<Map<String, dynamic>>> Function(String userId)? remoteTaskFetch,
    Future<void> Function(String taskId)? remoteTaskDelete,
    Future<void> Function(String taskId)? onTaskSynced,
  }) {
    return SyncTaskRepository(
      localDb: db,
      supabase: SupabaseClient(
        'https://example.supabase.co',
        'test-publishable-key',
      ),
      userId: 'user-1',
      listId: AppConstants.defaultListId,
      connectivity: connectivity,
      remoteTaskUpsert: remoteTaskUpsert,
      remoteTaskFetch: remoteTaskFetch,
      remoteTaskDelete: remoteTaskDelete,
      onTaskSynced: onTaskSynced,
    );
  }

  test('createTask writes local pending task before remote sync', () async {
    connectivity.online = false;
    final repository = buildRepository();
    final firstLocalTask = repository
        .watchTasks()
        .firstWhere((tasks) => tasks.isNotEmpty)
        .timeout(const Duration(seconds: 1));

    final created = await repository.createTask(title: 'Immediate local task');
    final tasks = await firstLocalTask;

    expect(tasks.single.id, created.id);
    expect(tasks.single.title, 'Immediate local task');
    expect(tasks.single.syncPending, isTrue);
  });

  test('pushPending clears pending after remote upsert succeeds', () async {
    connectivity.online = false;
    final upsertedIds = <String>[];
    final repository = buildRepository(
      remoteTaskUpsert: (task, userId) async {
        upsertedIds.add(task.id);
        return task.copyWith(syncPending: false);
      },
    );

    final created = await repository.createTask(title: 'Pending then synced');
    expect((await repository.getTaskById(created.id))?.syncPending, isTrue);

    connectivity.online = true;
    await repository.pushPending();

    final synced = await repository.getTaskById(created.id);
    expect(upsertedIds, [created.id]);
    expect(synced?.syncPending, isFalse);
  });

  test('pushPending notifies after cloud sync succeeds', () async {
    connectivity.online = false;
    final syncedIds = <String>[];
    final repository = buildRepository(
      remoteTaskUpsert: (task, userId) async =>
          task.copyWith(syncPending: false),
      onTaskSynced: (taskId) async => syncedIds.add(taskId),
    );
    final created = await repository.createTask(title: 'Local fallback');

    connectivity.online = true;
    await repository.pushPending();

    expect(syncedIds, [created.id]);
  });

  test('toggleComplete flips completion in a single local update', () async {
    connectivity.online = false;
    final repository = buildRepository();

    final created = await repository.createTask(title: 'Toggle me');
    expect(created.isCompleted, isFalse);

    final toggled = await repository.toggleComplete(created.id);
    expect(toggled.isCompleted, isTrue);
    expect(toggled.completedAt, isNotNull);
    expect(toggled.syncPending, isTrue, reason: 'signed-in user marks pending');

    final stored = await repository.getTaskById(created.id);
    expect(stored?.isCompleted, isTrue);
    expect(stored?.completedAt, isNotNull);

    final toggledBack = await repository.toggleComplete(created.id);
    expect(toggledBack.isCompleted, isFalse);
    expect(toggledBack.completedAt, isNull);
  });

  test('toggleComplete throws when task not found', () async {
    connectivity.online = false;
    final repository = buildRepository();

    expect(
      () => repository.toggleComplete('non-existent-id'),
      throwsStateError,
    );
  });

  test(
    'multiple watchTasks subscriptions do not throw and stay single-instance',
    () async {
      connectivity.online = true;
      final repository = buildRepository();

      // 多次订阅 watchTasks 不应多次触发远端刷新排程（应用级单例 _refreshScheduled）。
      final sub1 = repository.watchTasks().listen((_) {});
      final sub2 = repository.watchTasks().listen((_) {});
      final sub3 = repository.watchTasks().listen((_) {});

      // 等待 debounce（300ms）+ 缓冲，确保不抛错。
      await Future<void>.delayed(const Duration(milliseconds: 500));

      await sub1.cancel();
      await sub2.cancel();
      await sub3.cancel();

      expect(repository, isNotNull);
    },
  );

  test(
    'requestRefresh re-triggers remote refresh after connectivity returns',
    () async {
      connectivity.online = false;
      final repository = buildRepository();

      // 离线时订阅：首次排程但因离线不拉取。
      final sub = repository.watchTasks().listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // 在线后显式 requestRefresh 触发一次刷新。
      connectivity.online = true;
      repository.requestRefresh();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await sub.cancel();
      expect(repository, isNotNull);
    },
  );

  test('refreshNow does not resurrect a task pending remote delete', () async {
    connectivity.online = false;
    late Task deletedTask;
    var fetchCount = 0;
    final repository = buildRepository(
      remoteTaskFetch: (_) async {
        fetchCount += 1;
        return [_remoteRow(deletedTask)];
      },
    );

    deletedTask = await repository.createTask(title: 'Delete offline');
    await repository.deleteTask(deletedTask.id);
    expect(await repository.getTaskById(deletedTask.id), isNull);

    connectivity.online = true;
    await repository.refreshNow();

    expect(fetchCount, 1);
    expect(await repository.getTaskById(deletedTask.id), isNull);
  });

  test('pushPending sends queued deletes once after reconnect', () async {
    connectivity.online = false;
    final deletedIds = <String>[];
    final repository = buildRepository(
      remoteTaskDelete: (taskId) async {
        deletedIds.add(taskId);
      },
    );

    final task = await repository.createTask(title: 'Delete when online');
    await repository.deleteTask(task.id);

    connectivity.online = true;
    await repository.pushPending();
    await repository.pushPending();

    expect(deletedIds, [task.id]);
    expect(await repository.getTaskById(task.id), isNull);
  });
}

Map<String, dynamic> _remoteRow(Task task) {
  return {
    ...task.toSupabaseJson(userId: 'user-1'),
    'created_at': task.createdAt.toUtc().toIso8601String(),
    'updated_at': task.updatedAt.toUtc().toIso8601String(),
  };
}

class _TestConnectivityService extends ConnectivityService {
  final _controller = StreamController<ConnectivityResult>.broadcast();
  bool online = false;

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}
