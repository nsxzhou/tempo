// ============================================================
// app_providers — 全局 Riverpod Provider 配置
// 包含: Dio / Supabase / Auth / Database / Repository / SyncService
//       / NotificationService / TextParseService / VoiceTaskService
//       / SiyuanPairingService / FeedbackService / Connectivity
// ============================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/database_provider.dart';
import 'features/auth/data/auth_service.dart';
import 'features/settings/data/feedback_service.dart';
import 'features/settings/data/siyuan_pairing_service.dart';
import 'features/tasks/data/notification_service.dart';
import 'features/tasks/data/sync_service.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/data/text_parse_service.dart';
import 'features/tasks/data/voice_recorder.dart';
import 'features/tasks/data/voice_task_service.dart';
import 'features/tasks/domain/task.dart';

// Re-export auth providers so consumers of app_providers can access them.
export 'features/auth/data/auth_service.dart';

// ── Dio ──

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

// ── Supabase / Auth ──
// supabaseProvider, authServiceProvider, authStateProvider,
// currentUserIdProvider, currentUserEmailProvider
// 定义在 features/auth/data/auth_service.dart 中，通过 export 暴露。

// ── Connectivity ──

final connectivityProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Task Repository (SyncTaskRepository) ──

/// 默认 Inbox 列表 ID Provider。
///
/// Phase 1 所有任务归入默认 Inbox 列表。
/// Auth 接入后从 Supabase 查询用户的 Inbox 列表 ID，
/// 如果不存在则使用本地默认值。
final defaultListIdProvider = FutureProvider<String>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final supabase = ref.watch(supabaseProvider);

  if (userId == null) {
    return 'local-inbox';
  }

  try {
    final rows = await supabase
        .from(AppConstants.tableTaskLists)
        .select('id')
        .eq('user_id', userId)
        .eq('name', AppConstants.defaultListName)
        .limit(1);

    if (rows.isNotEmpty) {
      return rows[0]['id'] as String;
    }
  } catch (_) {
    // 查询失败，使用本地默认值
  }

  return 'local-inbox';
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  final connectivity = ref.watch(connectivityProvider);
  final listId = ref.watch(defaultListIdProvider).valueOrNull ?? 'local-inbox';

  return SyncTaskRepository(
    localDb: db,
    supabase: supabase,
    userId: userId,
    listId: listId,
    connectivity: connectivity,
  );
});

final taskListProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks();
});

// ── SyncService ──

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final connectivity = ref.watch(connectivityProvider);
  return SyncService(
    repository: repository,
    connectivity: connectivity,
  );
});

// ── NotificationService ──

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── TextParseService ──

final textParseServiceProvider = Provider<TextParseService>((ref) {
  final dio = ref.watch(dioProvider);
  return TextParseService(
    dio: dio,
    endpoint: AppConstants.parseTaskEndpoint,
  );
});

// ── VoiceTaskService ──

final voiceTaskServiceProvider = Provider<VoiceTaskService>((ref) {
  final dio = ref.watch(dioProvider);
  return DioVoiceTaskService(
    dio: dio,
    endpoint: AppConstants.parseTaskEndpoint,
  );
});

// ── VoiceRecorder ──

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();
  ref.onDispose(() {
    recorder.dispose();
  });
  return recorder;
});

// ── SiyuanPairingService ──

final siyuanPairingServiceProvider = Provider<SiyuanPairingService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  final userEmail = ref.watch(currentUserEmailProvider);
  return SiyuanPairingService(
    supabase: supabase,
    userId: userId,
    userEmail: userEmail,
  );
});

// ── FeedbackService ──

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FeedbackService(
    supabase: supabase,
    userId: userId,
  );
});
