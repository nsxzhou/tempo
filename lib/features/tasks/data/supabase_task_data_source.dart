// ============================================================
// SupabaseTaskDataSource — Supabase CRUD 数据源
// 封装 Supabase tasks 表的增删改查操作
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/task.dart' as domain;

/// Supabase tasks 表 CRUD 数据源。
///
/// 封装 Supabase 的 insert/update/delete/select 操作，
/// 供 [SyncTaskRepository] 调用。
class SupabaseTaskDataSource {
  final SupabaseClient _client;

  SupabaseTaskDataSource(this._client);

  /// 插入任务到 Supabase，返回完整行数据。
  Future<Map<String, dynamic>> insert(
    domain.Task task, {
    required String userId,
  }) async {
    final row = await _client
        .from(AppConstants.tableTasks)
        .insert(task.toSupabaseJson(userId: userId))
        .select()
        .single();
    return row as Map<String, dynamic>;
  }

  /// 更新任务到 Supabase，返回更新后的行数据。
  Future<Map<String, dynamic>> update(
    domain.Task task, {
    required String userId,
  }) async {
    final row = await _client
        .from(AppConstants.tableTasks)
        .update(task.toSupabaseJson(userId: userId))
        .eq('id', task.id)
        .select()
        .single();
    return row as Map<String, dynamic>;
  }

  /// Upsert 任务到 Supabase（last-write-wins）。
  Future<void> upsert(
    domain.Task task, {
    required String userId,
  }) async {
    await _client
        .from(AppConstants.tableTasks)
        .upsert(task.toSupabaseJson(userId: userId));
  }

  /// 从 Supabase 删除任务。
  Future<void> delete(String id) async {
    await _client.from(AppConstants.tableTasks).delete().eq('id', id);
  }

  /// 查询用户的所有任务。
  Future<List<Map<String, dynamic>>> selectByUser(String userId) async {
    final rows = await _client
        .from(AppConstants.tableTasks)
        .select()
        .eq('user_id', userId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// 查询单个任务。
  Future<Map<String, dynamic>?> selectById(String id) async {
    final rows = await _client
        .from(AppConstants.tableTasks)
        .select()
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows[0] as Map<String, dynamic>;
  }
}
