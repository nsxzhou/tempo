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
