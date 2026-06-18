// ============================================================
// TaskRepository — 任务数据仓库接口 + SyncTaskRepository 实现
// 在线优先策略：写入先云端后本地，读取先本地后后台刷新
// ============================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../database/database.dart' as db;
import '../domain/task.dart' as domain;
import 'voice_task_parse_result.dart';

/// 任务数据仓库接口。
///
/// 定义任务 CRUD 和同步操作。由 [SyncTaskRepository] 实现。
abstract class TaskRepository {
  /// 监听所有任务的响应式流（local-first + 后台刷新）。
  Stream<List<domain.Task>> watchTasks();

  /// 创建任务（在线优先：先写 Supabase，离线写本地标记 syncPending）。
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  });

  /// 从语音解析结果创建任务。
  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result);

  /// 更新任务字段（标题/描述/优先级/截止时间等）。
  Future<domain.Task> updateTask(domain.Task task);

  /// 切换任务完成状态，自动设置/清除 completedAt。
  Future<domain.Task> toggleComplete(String id);

  /// 删除任务。
  Future<void> deleteTask(String id);

  /// 按 listId 过滤的响应式流。
  Stream<List<domain.Task>> watchTasksByList(String listId);

  /// 按日期范围过滤（日历视图用）。
  Stream<List<domain.Task>> watchTasksByDateRange(
      DateTime start, DateTime end);

  /// 获取单个任务（详情页用）。
  Future<domain.Task?> getTaskById(String id);

  /// 推送离线待同步记录到云端（SyncService 调用）。
  Future<void> pushPending();
}

/// 网络连接服务封装。
///
/// 封装 connectivity_plus 提供在线/离线判断。
class ConnectivityService {
  final Connectivity _connectivity;
  ConnectivityResult _current = ConnectivityResult.none;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((result) {
      _current = result;
    });
  }

  /// 当前是否在线（非 none 即认为在线）。
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// 网络状态变化流。
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// 释放资源。
  void dispose() {
    // connectivity_plus 的 stream 不需要手动 cancel
  }
}

/// 在线优先同步任务仓库。
///
/// 写入路径（online-first）：
/// - 在线：先写 Supabase，成功后更新本地 Drift 缓存
/// - 离线：写 Drift，标记 syncPending=true，等待网络恢复后推送
///
/// 读取路径（local-first + background refresh）：
/// - 立即返回 Drift 流（毫秒级）
/// - 后台静默刷新 Supabase 数据到本地缓存
class SyncTaskRepository implements TaskRepository {
  final db.AppDatabase _localDb;
  final SupabaseClient _supabase;
  final String? _userId;
  final String _listId;
  final ConnectivityService _connectivity;
  final Uuid _uuid;

  SyncTaskRepository({
    required db.AppDatabase localDb,
    required SupabaseClient supabase,
    required String? userId,
    required String listId,
    required ConnectivityService connectivity,
    Uuid? uuid,
  })  : _localDb = localDb,
        _supabase = supabase,
        _userId = userId,
        _listId = listId,
        _connectivity = connectivity,
        _uuid = uuid ?? const Uuid();

  // ── 写入路径 ──

  @override
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    final task = domain.Task(
      id: id,
      listId: _listId,
      title: trimmedTitle,
      description: description?.trim(),
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
      syncPending: false,
    );

    final isOnline = await _connectivity.isOnline;
    if (isOnline && _userId != null) {
      try {
        // 1. 写 Supabase
        final row = await _supabase
            .from(AppConstants.tableTasks)
            .insert(task.toSupabaseJson(userId: _userId!))
            .select()
            .single();
        final remote = domain.TaskSupabase.fromSupabaseJson(row);
        // 2. 更新本地缓存
        await _upsertLocal(remote);
        return remote;
      } catch (_) {
        // Supabase 写入失败，降级为本地写入
        await _upsertLocal(task.copyWith(syncPending: true));
        return task;
      }
    } else {
      // 离线：写本地，标记 syncPending
      await _upsertLocal(task.copyWith(syncPending: true));
      return task;
    }
  }

  @override
  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result) {
    final description = result.description?.isNotEmpty == true
        ? result.description
        : '识别内容: ${result.rawTranscript}';

    return createTask(
      title: result.title,
      description: description,
      dueDate: result.dueDate,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
    );
  }

  @override
  Future<domain.Task> updateTask(domain.Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    final isOnline = await _connectivity.isOnline;

    if (isOnline && _userId != null) {
      try {
        final row = await _supabase
            .from(AppConstants.tableTasks)
            .update(updated.toSupabaseJson(userId: _userId!))
            .eq('id', updated.id)
            .select()
            .single();
        final remote = domain.TaskSupabase.fromSupabaseJson(row);
        await _upsertLocal(remote);
        return remote;
      } catch (_) {
        // 降级为本地写入
        await _upsertLocal(updated.copyWith(syncPending: true));
        return updated;
      }
    } else {
      await _upsertLocal(updated.copyWith(syncPending: true));
      return updated;
    }
  }

  @override
  Future<domain.Task> toggleComplete(String id) async {
    final current = await getTaskById(id);
    if (current == null) {
      throw StateError('Task not found: $id');
    }

    final now = DateTime.now();
    final toggled = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: !current.isCompleted ? now : null,
      updatedAt: now,
    );

    return updateTask(toggled);
  }

  @override
  Future<void> deleteTask(String id) async {
    // 先删本地
    await (_localDb.delete(_localDb.tasks)
          ..where((t) => t.id.equals(id)))
        .go();

    // 尝试删云端（失败静默忽略，本地已删）
    final isOnline = await _connectivity.isOnline;
    if (isOnline && _userId != null) {
      try {
        await _supabase
            .from(AppConstants.tableTasks)
            .delete()
            .eq('id', id);
      } catch (_) {
        // 静默忽略：本地已删除，云端会在下次同步时被忽略
      }
    }
  }

  // ── 读取路径 ──

  @override
  Stream<List<domain.Task>> watchTasks() {
    // 立即返回本地流（毫秒级）
    final localStream = (_localDb.select(_localDb.tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted),
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm.desc(t.dueDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(_mapTask).toList());

    // 后台静默刷新云端
    _refreshFromRemote();

    return localStream;
  }

  @override
  Stream<List<domain.Task>> watchTasksByList(String listId) {
    final localStream = (_localDb.select(_localDb.tasks)
          ..where((t) => t.listId.equals(listId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted),
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(_mapTask).toList());

    _refreshFromRemote();
    return localStream;
  }

  @override
  Stream<List<domain.Task>> watchTasksByDateRange(
      DateTime start, DateTime end) {
    final localStream = (_localDb.select(_localDb.tasks)
          ..where((t) => t.dueDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .watch()
        .map((rows) => rows.map(_mapTask).toList());

    _refreshFromRemote();
    return localStream;
  }

  @override
  Future<domain.Task?> getTaskById(String id) async {
    final row = await (_localDb.select(_localDb.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapTask(row);
  }

  // ── pending 推送 ──

  @override
  Future<void> pushPending() async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline || _userId == null) return;

    final pending = await (_localDb.select(_localDb.tasks)
          ..where((t) => t.syncPending.equals(true)))
        .get();

    for (final row in pending) {
      try {
        final task = _mapTask(row);
        // last-write-wins: 直接 upsert
        await _supabase
            .from(AppConstants.tableTasks)
            .upsert(task.toSupabaseJson(userId: _userId!));
        // 清除 syncPending
        await (_localDb.update(_localDb.tasks)
              ..where((t) => t.id.equals(row.id)))
            .write(const db.TasksCompanion(syncPending: Value(false)));
      } catch (_) {
        // 保留 pending，下次重试
      }
    }
  }

  // ── 内部方法 ──

  /// 后台静默刷新云端数据到本地缓存。
  Future<void> _refreshFromRemote() async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline || _userId == null) return;

    try {
      final rows = await _supabase
          .from(AppConstants.tableTasks)
          .select()
          .eq('user_id', _userId!);

      for (final row in rows as List) {
        final remote = domain.TaskSupabase.fromSupabaseJson(
            row as Map<String, dynamic>);
        // upsert 到本地，覆盖 syncPending=false 的记录
        await _upsertLocal(remote, overwriteIfNotPending: true);
      }
    } catch (_) {
      // 静默失败，下次重试
    }
  }

  /// 将 Task upsert 到本地 Drift 数据库。
  ///
  /// [overwriteIfNotPending] 为 true 时，仅覆盖本地 syncPending=false 的记录
  /// （用于后台刷新：不覆盖用户离线修改的待同步数据）。
  Future<void> _upsertLocal(
    domain.Task task, {
    bool overwriteIfNotPending = false,
  }) async {
    if (overwriteIfNotPending) {
      // 检查本地是否已有该任务且 syncPending=true
      final existing = await (_localDb.select(_localDb.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      if (existing != null && existing.syncPending) {
        // 本地有待同步的修改，不覆盖
        return;
      }
    }

    final companion = db.TasksCompanion(
      id: Value(task.id),
      listId: Value(task.listId),
      title: Value(task.title),
      description: Value(task.description),
      priority: Value(task.priority.value),
      dueDate: Value(task.dueDate),
      isCompleted: Value(task.isCompleted),
      completedAt: Value(task.completedAt),
      siyuanBlockId: Value(task.siyuanBlockId),
      sortOrder: Value(task.sortOrder),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      creationSource: Value(task.creationSource),
      syncPending: Value(task.syncPending),
    );

    await _localDb.into(_localDb.tasks).insertOnConflictUpdate(companion);
  }

  /// 将 Drift 行映射为领域模型 Task。
  domain.Task _mapTask(db.Task row) {
    return domain.Task(
      id: row.id,
      listId: row.listId,
      title: row.title,
      description: row.description,
      priority: domain.TaskPriority.fromValue(row.priority),
      dueDate: row.dueDate,
      isCompleted: row.isCompleted,
      completedAt: row.completedAt,
      siyuanBlockId: row.siyuanBlockId,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      creationSource: row.creationSource,
      syncPending: row.syncPending,
    );
  }
}

// ── 保留旧类名以兼容测试 ──
/// @deprecated 使用 SyncTaskRepository 替代。
class DriftTaskRepository implements TaskRepository {
  static const String defaultListId = 'local-inbox';
  static const String defaultUserId = 'local-user';

  final db.AppDatabase _database;
  final Uuid _uuid;

  DriftTaskRepository(this._database, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<domain.Task>> watchTasks() async* {
    final query = _database.select(_database.tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    yield* query.watch().map((rows) => rows.map(_mapTask).toList());
  }

  @override
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  }) async {
    final now = DateTime.now();
    final trimmedTitle = title.trim();
    final id = _uuid.v4();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty');
    }

    final companion = db.TasksCompanion.insert(
      id: id,
      listId: defaultListId,
      title: trimmedTitle,
      description: Value(description?.trim()),
      priority: Value(priority.value),
      dueDate: Value(dueDate),
      createdAt: Value(now),
      updatedAt: Value(now),
      creationSource: Value(creationSource),
    );

    await _database.into(_database.tasks).insert(companion);

    return domain.Task(
      id: id,
      listId: defaultListId,
      title: trimmedTitle,
      description: description?.trim(),
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
    );
  }

  @override
  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result) {
    final description = result.description?.isNotEmpty == true
        ? result.description
        : '识别内容: ${result.rawTranscript}';

    return createTask(
      title: result.title,
      description: description,
      dueDate: result.dueDate,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
    );
  }

  @override
  Future<domain.Task> updateTask(domain.Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await (_database.update(_database.tasks)
          ..where((t) => t.id.equals(updated.id)))
        .write(db.TasksCompanion(
      title: Value(updated.title),
      description: Value(updated.description),
      priority: Value(updated.priority.value),
      dueDate: Value(updated.dueDate),
      updatedAt: Value(updated.updatedAt),
    ));
    return updated;
  }

  @override
  Future<domain.Task> toggleComplete(String id) async {
    final row = await (_database.select(_database.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final now = DateTime.now();
    final newCompleted = !row.isCompleted;
    await (_database.update(_database.tasks)
          ..where((t) => t.id.equals(id)))
        .write(db.TasksCompanion(
      isCompleted: Value(newCompleted),
      completedAt: Value(newCompleted ? now : null),
      updatedAt: Value(now),
    ));
    return _mapTask(row).copyWith(
      isCompleted: newCompleted,
      completedAt: newCompleted ? now : null,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteTask(String id) {
    return (_database.delete(_database.tasks)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Stream<List<domain.Task>> watchTasksByList(String listId) {
    return (_database.select(_database.tasks)
          ..where((t) => t.listId.equals(listId)))
        .watch()
        .map((rows) => rows.map(_mapTask).toList());
  }

  @override
  Stream<List<domain.Task>> watchTasksByDateRange(
      DateTime start, DateTime end) {
    return (_database.select(_database.tasks)
          ..where((t) => t.dueDate.isBetweenValues(start, end)))
        .watch()
        .map((rows) => rows.map(_mapTask).toList());
  }

  @override
  Future<domain.Task?> getTaskById(String id) async {
    final row = await (_database.select(_database.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapTask(row);
  }

  @override
  Future<void> pushPending() async {}

  domain.Task _mapTask(db.Task row) {
    return domain.Task(
      id: row.id,
      listId: row.listId,
      title: row.title,
      description: row.description,
      priority: domain.TaskPriority.fromValue(row.priority),
      dueDate: row.dueDate,
      isCompleted: row.isCompleted,
      completedAt: row.completedAt,
      siyuanBlockId: row.siyuanBlockId,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      creationSource: row.creationSource,
      syncPending: row.syncPending,
    );
  }
}
