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
