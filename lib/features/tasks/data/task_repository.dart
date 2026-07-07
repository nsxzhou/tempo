// ============================================================
// TaskRepository — 任务数据仓库接口 + SyncTaskRepository 实现
// 本地优先交互：写入先落 Drift，后台同步云端；读取先本地后后台刷新
// ============================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/sync_guard.dart';
import '../../../database/database.dart' as db;
import '../domain/task.dart' as domain;
import 'voice_task_parse_result.dart';

/// 任务数据仓库接口。
///
/// 定义任务 CRUD 和同步操作。由 [SyncTaskRepository] 实现。
abstract class TaskRepository {
  /// 监听所有任务的响应式流（local-first + 后台刷新）。
  Stream<List<domain.Task>> watchTasks();

  /// 创建任务（本地优先：先写 Drift，后台同步 Supabase）。
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    bool isAllDay = false,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
    String? tag,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    int? recurrenceCount,
    int? durationMin,
  });

  /// 从语音解析结果创建任务。
  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result);

  /// 更新任务字段（标题/描述/优先级/截止时间等）。
  Future<domain.Task> updateTask(domain.Task task);

  /// 切换任务完成状态，自动设置/清除 completedAt。
  /// 重复任务请使用 [toggleOccurrenceComplete]。
  Future<domain.Task> toggleComplete(String id);

  /// 切换重复任务某次 occurrence 的完成状态。
  Future<void> toggleOccurrenceComplete(
    String taskId,
    DateTime occurrenceDate, {
    required bool complete,
  });

  /// 删除任务。
  Future<void> deleteTask(String id);

  /// 获取单个任务（详情页用）。
  Future<domain.Task?> getTaskById(String id);

  /// 推送离线待同步记录到云端（SyncService 调用）。
  Future<void> pushPending();

  /// 请求一次后台远端刷新（连接恢复 / 用户变更 / 下拉刷新触发）。
  void requestRefresh();

  /// 立即执行一次同步刷新（下拉刷新等需要等待完成的交互触发）。
  Future<void> refreshNow();
}

/// 网络连接服务封装。
///
/// 封装 connectivity_plus 提供在线/离线判断。
/// connectivity_plus 5.x 把 onConnectivityChanged 类型从 `Stream<ConnectivityResult>`
/// 升级为 `Stream<List<ConnectivityResult>>`（多网卡场景）。
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// 当前是否在线（非 none 即认为在线）。
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// 网络状态变化流（把 List 折叠成单个值,兼容老接口）。
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.isEmpty ? ConnectivityResult.none : results.first,
      );

  /// 释放资源。
  void dispose() {
    // connectivity_plus 的 stream 不需要手动 cancel
  }
}

/// 本地优先同步任务仓库。
///
/// 写入路径（optimistic local-first）：
/// - 先写 Drift，让 UI 立即响应
/// - 有登录用户时标记 syncPending=true，并后台同步 Supabase
/// - 同步成功后把确认行写回 Drift，syncPending=false
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
  final Future<domain.Task> Function(domain.Task task, String userId)?
  _remoteTaskUpsert;
  final Future<List<Map<String, dynamic>>> Function(String userId)?
  _remoteTaskFetch;
  final Future<void> Function(String taskId)? _remoteTaskDelete;
  final Future<void> Function(
    String taskId,
    DateTime occurrenceDate,
    bool complete,
  )?
  _occurrenceToggle;
  final Future<void> Function(List<String> taskIds)? _recurrenceRefresh;
  Timer? _refreshDebounce;
  Future<void>? _refreshInFlight;

  SyncTaskRepository({
    required db.AppDatabase localDb,
    required SupabaseClient supabase,
    required String? userId,
    required String listId,
    required ConnectivityService connectivity,
    Uuid? uuid,
    Future<domain.Task> Function(domain.Task task, String userId)?
    remoteTaskUpsert,
    Future<List<Map<String, dynamic>>> Function(String userId)? remoteTaskFetch,
    Future<void> Function(String taskId)? remoteTaskDelete,
    Future<void> Function(
      String taskId,
      DateTime occurrenceDate,
      bool complete,
    )?
    occurrenceToggle,
    Future<void> Function(List<String> taskIds)? recurrenceRefresh,
  }) : _localDb = localDb,
       _supabase = supabase,
       _userId = userId,
       _listId = listId,
       _connectivity = connectivity,
       _uuid = uuid ?? const Uuid(),
       _remoteTaskUpsert = remoteTaskUpsert,
       _remoteTaskFetch = remoteTaskFetch,
       _remoteTaskDelete = remoteTaskDelete,
       _occurrenceToggle = occurrenceToggle,
       _recurrenceRefresh = recurrenceRefresh;

  // ── 写入路径 ──

  @override
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    bool isAllDay = false,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
    String? tag,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    int? recurrenceCount,
    int? durationMin,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    final shouldSync = _userId != null;
    final task = domain.Task(
      id: id,
      listId: _listId,
      title: trimmedTitle,
      description: description?.trim(),
      priority: priority,
      dueDate: dueDate,
      isAllDay: isAllDay,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
      tag: tag,
      recurrenceRule: recurrenceRule,
      recurrenceEnd: recurrenceEnd,
      recurrenceCount: recurrenceCount,
      durationMin: durationMin,
      syncPending: shouldSync,
    );

    await _upsertLocal(task);
    if (shouldSync) {
      unawaited(_syncTaskToCloud(task));
    }
    return task;
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
      isAllDay: result.isAllDay,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
      tag: result.tag,
      recurrenceRule: result.recurrenceRule,
      recurrenceEnd: result.recurrenceEnd,
      recurrenceCount: result.recurrenceCount,
      durationMin: result.durationMin,
    );
  }

  @override
  Future<domain.Task> updateTask(domain.Task task) async {
    final shouldSync = _userId != null;
    final updated = task.copyWith(
      updatedAt: DateTime.now(),
      syncPending: shouldSync,
    );

    await _upsertLocal(updated);
    if (shouldSync) {
      unawaited(_syncTaskToCloud(updated));
    }
    return updated;
  }

  @override
  Future<domain.Task> toggleComplete(String id) async {
    final current = await getTaskById(id);
    if (current == null) {
      throw StateError('Task not found: $id');
    }

    final now = DateTime.now();
    final newCompleted = !current.isCompleted;
    final shouldSync = _userId != null;

    // 单条 update 翻转，仅写变化列，避免 updateTask 的全列 insertOnConflictUpdate。
    await (_localDb.update(
      _localDb.tasks,
    )..where((t) => t.id.equals(id))).write(
      db.TasksCompanion(
        isCompleted: Value(newCompleted),
        completedAt: Value(newCompleted ? now : null),
        updatedAt: Value(now),
        syncPending: Value(shouldSync),
      ),
    );

    final toggled = newCompleted
        ? current.copyWith(
            isCompleted: true,
            completedAt: now,
            updatedAt: now,
            syncPending: shouldSync,
          )
        : current.copyWith(
            isCompleted: false,
            clearCompletedAt: true,
            updatedAt: now,
            syncPending: shouldSync,
          );

    if (shouldSync) {
      unawaited(_syncTaskToCloud(toggled));
    }
    return toggled;
  }

  @override
  Future<void> toggleOccurrenceComplete(
    String taskId,
    DateTime occurrenceDate, {
    required bool complete,
  }) async {
    final handler = _occurrenceToggle;
    if (handler != null) {
      await handler(taskId, occurrenceDate, complete);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await _localDb.transaction(() async {
      if (_userId != null) {
        await _localDb
            .into(_localDb.taskDeletionOutbox)
            .insertOnConflictUpdate(
              db.TaskDeletionOutboxCompanion.insert(
                taskId: id,
                deletedAt: Value(DateTime.now()),
                syncPending: const Value(true),
              ),
            );
      }
      await (_localDb.delete(
        _localDb.tasks,
      )..where((t) => t.id.equals(id))).go();
    });

    unawaited(_syncDeleteToCloud(id));
  }

  Future<void> _syncDeleteToCloud(String id) async {
    final guard = SyncGuard(_connectivity, _userId);
    await guard.executeIfCanSync((userId) async {
      try {
        await _deleteRemoteTask(id);
        await (_localDb.delete(
          _localDb.taskDeletionOutbox,
        )..where((d) => d.taskId.equals(id))).go();
      } catch (_) {
        // 静默忽略：本地已删除
      }
    });
  }

  Future<void> _syncTaskToCloud(domain.Task task) async {
    final guard = SyncGuard(_connectivity, _userId);
    await guard.executeIfCanSync((userId) async {
      try {
        final remote = await _upsertRemoteTask(task, userId);
        await _upsertLocal(remote.copyWith(syncPending: false));
      } catch (_) {
        // Keep syncPending=true; SyncService.pushPending retries later.
      }
    });
  }

  // ── 读取路径 ──

  /// 修复 dueDate 为空但有 recurrenceRule 的脏数据（用 createdAt 作锚点）。
  Future<void> repairRecurringTasksMissingDueDate() async {
    final rows = await (_localDb.select(
      _localDb.tasks,
    )..where((t) => t.recurrenceRule.isNotNull() & t.dueDate.isNull())).get();

    for (final row in rows) {
      final rule = row.recurrenceRule?.trim();
      if (rule == null || rule.isEmpty) continue;

      final anchor = row.createdAt;
      final dueDate = calendarDay(anchor);
      final now = DateTime.now();
      final shouldSync = _userId != null;

      await (_localDb.update(
        _localDb.tasks,
      )..where((t) => t.id.equals(row.id))).write(
        db.TasksCompanion(
          dueDate: Value(dueDate),
          isAllDay: const Value(true),
          updatedAt: Value(now),
          syncPending: Value(shouldSync),
        ),
      );

      if (shouldSync) {
        final repaired = _mapTask(row).copyWith(
          dueDate: dueDate,
          isAllDay: true,
          updatedAt: now,
          syncPending: true,
        );
        unawaited(_syncTaskToCloud(repaired));
      }
    }
  }

  @override
  Stream<List<domain.Task>> watchTasks() {
    // 立即返回本地流（毫秒级）。远端刷新由应用级单例驱动（首次订阅 +
    // 连接恢复 + 用户变更），不再每次订阅触发。
    final localStream =
        (_localDb.select(_localDb.tasks)..orderBy([
              (t) => OrderingTerm(expression: t.isCompleted),
              (t) => OrderingTerm(expression: t.priority),
              (t) => OrderingTerm.desc(t.dueDate),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
            .watch()
            .map((rows) => rows.map(_mapTask).toList());

    _ensureRefreshScheduled();

    return localStream;
  }

  bool _refreshScheduled = false;

  /// 应用级单例刷新：仅首次订阅触发一次 debounce 排程；后续由
  /// [requestRefresh]（连接恢复 / 用户变更）显式驱动。
  void _ensureRefreshScheduled() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    _scheduleRefreshFromRemote();
  }

  /// 外部触发一次远端刷新（连接恢复、用户变更、下拉刷新）。
  @override
  void requestRefresh() {
    _scheduleRefreshFromRemote();
  }

  @override
  Future<void> refreshNow() async {
    _refreshDebounce?.cancel();
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final refresh = _refreshFromRemote();
    _refreshInFlight = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  void _scheduleRefreshFromRemote() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refreshNow());
    });
  }

  @override
  Future<domain.Task?> getTaskById(String id) async {
    final row = await (_localDb.select(
      _localDb.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _mapTask(row);
  }

  // ── pending 推送 ──

  @override
  Future<void> pushPending() async {
    final guard = SyncGuard(_connectivity, _userId);
    await guard.executeIfCanSync((userId) async {
      final pending = await (_localDb.select(
        _localDb.tasks,
      )..where((t) => t.syncPending.equals(true))).get();

      final clearedIds = <String>[];
      for (final row in pending) {
        try {
          final task = _mapTask(row);
          final remote = await _upsertRemoteTask(task, userId);
          await _upsertLocal(remote.copyWith(syncPending: false));
          clearedIds.add(row.id);
        } catch (_) {
          // 保留 pending，下次重试
        }
      }

      if (clearedIds.isNotEmpty) {
        await _localDb.batch((batch) {
          for (final id in clearedIds) {
            batch.update(
              _localDb.tasks,
              const db.TasksCompanion(syncPending: Value(false)),
              where: (t) => t.id.equals(id),
            );
          }
        });
      }

      await _pushPendingDeletes();
    });
  }

  // ── 内部方法 ──

  Future<domain.Task> _upsertRemoteTask(domain.Task task, String userId) async {
    final injected = _remoteTaskUpsert;
    if (injected != null) {
      return injected(task, userId);
    }

    final row = await _supabase
        .from(AppConstants.tableTasks)
        .upsert(task.toSupabaseJson(userId: userId))
        .select()
        .single();
    return domain.TaskSupabase.fromSupabaseJson(row);
  }

  Future<List<Map<String, dynamic>>> _fetchRemoteTasks(String userId) async {
    final injected = _remoteTaskFetch;
    if (injected != null) {
      return injected(userId);
    }

    final rows = await _supabase
        .from(AppConstants.tableTasks)
        .select()
        .eq('user_id', userId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> _deleteRemoteTask(String taskId) async {
    final injected = _remoteTaskDelete;
    if (injected != null) {
      await injected(taskId);
      return;
    }

    await _supabase.from(AppConstants.tableTasks).delete().eq('id', taskId);
  }

  Future<void> _pushPendingDeletes() async {
    final pendingDeletes = await (_localDb.select(
      _localDb.taskDeletionOutbox,
    )..where((d) => d.syncPending.equals(true))).get();

    for (final row in pendingDeletes) {
      try {
        await _deleteRemoteTask(row.taskId);
        await (_localDb.delete(
          _localDb.taskDeletionOutbox,
        )..where((d) => d.taskId.equals(row.taskId))).go();
      } catch (_) {
        // 保留 tombstone，下次网络恢复或手动刷新时重试。
      }
    }
  }

  /// 后台静默刷新云端数据到本地缓存。
  Future<void> _refreshFromRemote() async {
    try {
      final guard = SyncGuard(_connectivity, _userId);
      await guard.executeIfCanSync((userId) async {
        final rows = await _fetchRemoteTasks(userId);

        final pendingIds = await (_localDb.select(
          _localDb.tasks,
        )..where((t) => t.syncPending.equals(true))).map((r) => r.id).get();
        final pendingSet = pendingIds.toSet();

        final pendingDeleteIds = await (_localDb.select(
          _localDb.taskDeletionOutbox,
        )..where((d) => d.syncPending.equals(true))).map((r) => r.taskId).get();
        final pendingDeleteSet = pendingDeleteIds.toSet();

        final recurringIds = <String>[];

        await _localDb.batch((batch) {
          for (final map in rows) {
            final remote = domain.TaskSupabase.fromSupabaseJson(map);
            if (pendingSet.contains(remote.id) ||
                pendingDeleteSet.contains(remote.id)) {
              continue;
            }
            batch.insert(
              _localDb.tasks,
              _companionFor(remote),
              mode: InsertMode.insertOrReplace,
            );
            if (map['recurrence_rule'] != null) {
              recurringIds.add(remote.id);
            }
          }
        });

        final refreshRecurrence = _recurrenceRefresh;
        if (refreshRecurrence != null && recurringIds.isNotEmpty) {
          await refreshRecurrence(recurringIds);
        }
      });
    } catch (_) {
      // 静默失败，下次重试
    }
  }

  db.TasksCompanion _companionFor(domain.Task task) {
    return db.TasksCompanion(
      id: Value(task.id),
      listId: Value(task.listId),
      title: Value(task.title),
      description: Value(task.description),
      priority: Value(task.priority.value),
      dueDate: Value(task.dueDate),
      isAllDay: Value(task.isAllDay),
      isCompleted: Value(task.isCompleted),
      completedAt: Value(task.completedAt),
      siyuanBlockId: Value(task.siyuanBlockId),
      sortOrder: Value(task.sortOrder),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      creationSource: Value(task.creationSource),
      tag: Value(task.tag),
      recurrenceRule: Value(task.recurrenceRule),
      recurrenceEnd: Value(task.recurrenceEnd),
      recurrenceCount: Value(task.recurrenceCount),
      durationMin: Value(task.durationMin),
      recurrenceSeriesId: Value(task.recurrenceSeriesId),
      syncPending: Value(task.syncPending),
    );
  }

  /// 将 Task upsert 到本地 Drift 数据库。
  ///
  Future<void> _upsertLocal(domain.Task task) async {
    final companion = _companionFor(task);
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
      isAllDay: row.isAllDay,
      isCompleted: row.isCompleted,
      completedAt: row.completedAt,
      siyuanBlockId: row.siyuanBlockId,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      creationSource: row.creationSource,
      tag: row.tag,
      recurrenceRule: row.recurrenceRule,
      recurrenceEnd: row.recurrenceEnd,
      recurrenceCount: row.recurrenceCount,
      durationMin: row.durationMin,
      recurrenceSeriesId: row.recurrenceSeriesId,
      syncPending: row.syncPending,
    );
  }
}
