// ============================================================
// RecurrenceRepository — 重复任务完成记录与例外 CRUD + 同步
// ============================================================

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/task_filter.dart';
import '../../../core/utils/sync_guard.dart';
import '../../../database/database.dart' as db;
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart' as domain;
import 'task_repository.dart';

/// 完成记录与例外数据访问
class RecurrenceRepository {
  RecurrenceRepository({
    required db.AppDatabase localDb,
    required SupabaseClient supabase,
    required String? userId,
    required ConnectivityService connectivity,
  }) : _localDb = localDb,
       _supabase = supabase,
       _userId = userId,
       _connectivity = connectivity;

  final db.AppDatabase _localDb;
  final SupabaseClient _supabase;
  final String? _userId;
  final ConnectivityService _connectivity;
  final RecurrenceEngine _engine = const RecurrenceEngine();

  Stream<List<TaskCompletion>> watchCompletions() {
    return _localDb.select(_localDb.taskCompletions).watch().map(
      (rows) => rows.map(_mapCompletion).toList(),
    );
  }

  Stream<List<RecurrenceException>> watchExceptions() {
    return _localDb.select(_localDb.taskRecurrenceExceptions).watch().map(
      (rows) => rows.map(_mapException).toList(),
    );
  }

  Future<List<TaskCompletion>> completionsForTask(String taskId) async {
    final rows = await (_localDb.select(
      _localDb.taskCompletions,
    )..where((c) => c.taskId.equals(taskId))).get();
    return rows.map(_mapCompletion).toList();
  }

  Future<List<RecurrenceException>> exceptionsForTask(String taskId) async {
    final rows = await (_localDb.select(
      _localDb.taskRecurrenceExceptions,
    )..where((e) => e.taskId.equals(taskId))).get();
    return rows.map(_mapException).toList();
  }

  /// 打卡：写入 completion 记录
  Future<void> completeOccurrence({
    required String taskId,
    required DateTime occurrenceDate,
  }) async {
    final day = RecurrenceEngine.calendarDay(occurrenceDate);
    final now = DateTime.now();
    final shouldSync = _userId != null;

    await _localDb
        .into(_localDb.taskCompletions)
        .insertOnConflictUpdate(
          db.TaskCompletionsCompanion.insert(
            taskId: taskId,
            occurrenceDate: day,
            completedAt: Value(now),
            syncPending: Value(shouldSync),
          ),
        );

    if (shouldSync) {
      unawaited(_syncCompletionToCloud(taskId, day, now));
    }
  }

  /// 取消打卡
  Future<void> uncompleteOccurrence({
    required String taskId,
    required DateTime occurrenceDate,
  }) async {
    final day = RecurrenceEngine.calendarDay(occurrenceDate);
    await (_localDb.delete(
      _localDb.taskCompletions,
    )..where(
      (c) => c.taskId.equals(taskId) & c.occurrenceDate.equals(day),
    )).go();

    unawaited(_syncDeleteCompletion(taskId, day));
  }

  /// 切换 occurrence 完成状态
  Future<void> toggleOccurrenceComplete({
    required domain.Task task,
    required DateTime occurrenceDate,
    required bool complete,
  }) async {
    if (complete) {
      await completeOccurrence(taskId: task.id, occurrenceDate: occurrenceDate);
    } else {
      await uncompleteOccurrence(taskId: task.id, occurrenceDate: occurrenceDate);
    }
  }

  /// 添加例外（跳过或 override）
  Future<void> upsertException(RecurrenceException exception) async {
    final shouldSync = _userId != null;
    final day = RecurrenceEngine.calendarDay(exception.exceptionDate);

    await _localDb
        .into(_localDb.taskRecurrenceExceptions)
        .insertOnConflictUpdate(
          db.TaskRecurrenceExceptionsCompanion.insert(
            taskId: exception.taskId,
            exceptionDate: day,
            overrideDue: Value(exception.overrideDue),
            overrideTitle: Value(exception.overrideTitle),
            isCancelled: Value(exception.isCancelled),
            syncPending: Value(shouldSync),
          ),
        );

    if (shouldSync) {
      unawaited(_syncExceptionToCloud(
        RecurrenceException(
          taskId: exception.taskId,
          exceptionDate: day,
          overrideDue: exception.overrideDue,
          overrideTitle: exception.overrideTitle,
          isCancelled: exception.isCancelled,
        ),
      ));
    }
  }

  /// 编辑「仅此 occurrence」
  Future<void> editThisOccurrence({
    required domain.Task task,
    required DateTime occurrenceDate,
    DateTime? overrideDue,
    String? overrideTitle,
    bool cancel = false,
  }) async {
    await upsertException(
      RecurrenceException(
        taskId: task.id,
        exceptionDate: occurrenceDate,
        overrideDue: overrideDue,
        overrideTitle: overrideTitle,
        isCancelled: cancel,
      ),
    );
  }

  /// 编辑「此及之后」：截断旧系列 end，由调用方创建新 task
  domain.Task truncateSeriesAt(domain.Task task, DateTime fromDate) {
    final day = RecurrenceEngine.calendarDay(fromDate);
    return task.copyWith(
      recurrenceEnd: day.subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
  }

  StreakInfo streakFor(
    domain.Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) {
    return _engine.computeStreak(
      task,
      completions: completions.forTask(task.id, (c) => c.taskId),
      exceptions: exceptions.forTask(task.id, (e) => e.taskId),
    );
  }

  Future<void> refreshFromRemote(List<String> taskIds) async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline || taskIds.isEmpty) return;

    try {
      final completionRows = await _supabase
          .from(AppConstants.tableTaskCompletions)
          .select()
          .inFilter('task_id', taskIds);

      final exceptionRows = await _supabase
          .from(AppConstants.tableRecurrenceExceptions)
          .select()
          .inFilter('task_id', taskIds);

      await _localDb.batch((batch) {
        for (final row in completionRows as List) {
          final map = row as Map<String, dynamic>;
          batch.insert(
            _localDb.taskCompletions,
            db.TaskCompletionsCompanion.insert(
              taskId: map['task_id'] as String,
              occurrenceDate: DateTime.parse(map['occurrence_date'] as String),
              completedAt: Value(
                DateTime.parse(map['completed_at'] as String),
              ),
              syncPending: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
        for (final row in exceptionRows as List) {
          final map = row as Map<String, dynamic>;
          batch.insert(
            _localDb.taskRecurrenceExceptions,
            db.TaskRecurrenceExceptionsCompanion.insert(
              taskId: map['task_id'] as String,
              exceptionDate: DateTime.parse(map['exception_date'] as String),
              overrideDue: Value(
                map['override_due'] != null
                    ? DateTime.parse(map['override_due'] as String)
                    : null,
              ),
              overrideTitle: Value(map['override_title'] as String?),
              isCancelled: Value(map['is_cancelled'] as bool? ?? false),
              syncPending: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    } catch (_) {
      // 静默失败
    }
  }

  Future<void> pushPending() async {
    final guard = SyncGuard(_connectivity, _userId);
    await guard.executeIfCanSync((userId) async {
      final pendingCompletions = await (_localDb.select(
        _localDb.taskCompletions,
      )..where((c) => c.syncPending.equals(true))).get();

      for (final row in pendingCompletions) {
        try {
          await _syncCompletionToCloud(
            row.taskId,
            row.occurrenceDate,
            row.completedAt,
          );
          await (_localDb.update(_localDb.taskCompletions)
                ..where(
                  (c) =>
                      c.taskId.equals(row.taskId) &
                      c.occurrenceDate.equals(row.occurrenceDate),
                ))
              .write(const db.TaskCompletionsCompanion(syncPending: Value(false)));
        } catch (_) {}
      }

      final pendingExceptions = await (_localDb.select(
        _localDb.taskRecurrenceExceptions,
      )..where((e) => e.syncPending.equals(true))).get();

      for (final row in pendingExceptions) {
        try {
          await _syncExceptionToCloud(_mapException(row));
          await (_localDb.update(_localDb.taskRecurrenceExceptions)
                ..where(
                  (e) =>
                      e.taskId.equals(row.taskId) &
                      e.exceptionDate.equals(row.exceptionDate),
                ))
              .write(
                const db.TaskRecurrenceExceptionsCompanion(
                  syncPending: Value(false),
                ),
              );
        } catch (_) {}
      }
    });
  }

  Future<void> _syncCompletionToCloud(
    String taskId,
    DateTime occurrenceDate,
    DateTime completedAt,
  ) async {
    final guard = SyncGuard(_connectivity, _userId);
    await guard.executeIfCanSync((userId) async {
      await _supabase.from(AppConstants.tableTaskCompletions).upsert({
        'task_id': taskId,
        'occurrence_date': _dateOnly(occurrenceDate),
        'completed_at': completedAt.toUtc().toIso8601String(),
      });
    });
  }

  Future<void> _syncDeleteCompletion(
    String taskId,
    DateTime occurrenceDate,
  ) async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) return;

    try {
      await _supabase
          .from(AppConstants.tableTaskCompletions)
          .delete()
          .eq('task_id', taskId)
          .eq('occurrence_date', _dateOnly(occurrenceDate));
    } catch (_) {}
  }

  Future<void> _syncExceptionToCloud(RecurrenceException ex) async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) return;

    await _supabase.from(AppConstants.tableRecurrenceExceptions).upsert({
      'task_id': ex.taskId,
      'exception_date': _dateOnly(ex.exceptionDate),
      'override_due': ex.overrideDue?.toUtc().toIso8601String(),
      'override_title': ex.overrideTitle,
      'is_cancelled': ex.isCancelled,
    });
  }

  String _dateOnly(DateTime dt) {
    final d = RecurrenceEngine.calendarDay(dt);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  TaskCompletion _mapCompletion(db.TaskCompletion row) => TaskCompletion(
    taskId: row.taskId,
    occurrenceDate: RecurrenceEngine.calendarDay(row.occurrenceDate),
    completedAt: row.completedAt,
    syncPending: row.syncPending,
  );

  RecurrenceException _mapException(db.TaskRecurrenceException row) =>
      RecurrenceException(
        taskId: row.taskId,
        exceptionDate: row.exceptionDate,
        overrideDue: row.overrideDue,
        overrideTitle: row.overrideTitle,
        isCancelled: row.isCancelled,
        syncPending: row.syncPending,
      );
}
