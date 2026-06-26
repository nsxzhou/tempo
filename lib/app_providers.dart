// ============================================================
// app_providers — 全局 Riverpod Provider 配置
// 包含: Dio / Supabase / Auth / Database / Repository / SyncService
//       / NotificationService / TextParseService
//       / SiyuanPairingService / FeedbackService / Connectivity
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/database_provider.dart';
import 'features/auth/data/auth_service.dart';
import 'features/settings/data/feedback_service.dart';
import 'features/settings/data/siyuan_pairing_service.dart';
import 'features/tasks/data/notification_service.dart';
import 'features/tasks/data/sync_service.dart';
import 'features/tasks/data/task_repository.dart';
import 'core/router/app_router.dart';
import 'features/tasks/data/streaming_voice_session.dart';
import 'features/tasks/data/task_creation_orchestrator.dart';
import 'features/tasks/data/text_parse_service.dart';
import 'features/tasks/data/voice_recorder.dart';
import 'features/tasks/data/volcengine_streaming_asr.dart';
import 'features/tasks/domain/task.dart';
import 'features/stats/data/stats_repository.dart';
import 'features/stats/domain/stats_models.dart';
import 'features/tasks/domain/task_counts.dart';

// Re-export auth providers so consumers of app_providers can access them.
export 'features/auth/data/auth_service.dart';

// ── Shell ──
final shellTabBarVisibleProvider = StateProvider<bool>((ref) => true);

/// push 详情前同步置 true，避免 Shell 未及时 rebuild 导致列表透出。
final taskDetailOverlayProvider = StateProvider<bool>((ref) => false);

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
    return AppConstants.defaultListId;
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

  return AppConstants.defaultListId;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  final connectivity = ref.watch(connectivityProvider);
  final listId =
      ref.watch(defaultListIdProvider).valueOrNull ??
      AppConstants.defaultListId;

  final repository = SyncTaskRepository(
    localDb: db,
    supabase: supabase,
    userId: userId,
    listId: listId,
    connectivity: connectivity,
  );

  // 应用级单例刷新触发：连接恢复 + 用户变更。
  final connectivitySub = connectivity.onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      repository.requestRefresh();
    }
  });
  ref.onDispose(connectivitySub.cancel);

  // 用户切换时刷新一次（登录/换号后拉取新用户数据）。
  ref.listen<String?>(currentUserIdProvider, (_, _) {
    repository.requestRefresh();
  });

  return repository;
});

final taskListProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks();
}, name: 'taskListProvider');

/// 任务 id → Task 索引，供 taskByIdProvider O(1) 查找。
final taskMapProvider = Provider<Map<String, Task>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
  return {for (final t in tasks) t.id: t};
});

/// 从 taskListProvider 缓存按 id 查找；详情页首帧优先使用，避免 loading 闪屏。
final taskByIdProvider = Provider.family<Task?, String>((ref, id) {
  return ref.watch(taskMapProvider)[id];
});

/// 统计页快照（内存聚合，移出 build）。
final statsSnapshotProvider = Provider.family<StatsSnapshot, int>((ref, days) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
  if (tasks.isEmpty) return StatsSnapshot.empty(days);
  return ref.read(statsRepositoryProvider).computeSnapshot(tasks, days);
}, name: 'statsSnapshotProvider');

/// 单次遍历的任务计数（Bento + 分类筛选共用）。
final taskCountsProvider = Provider<TaskCounts>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
  return TaskCounts.from(tasks);
});

/// 按 dueDate 日历日索引（月视图 O(42) 查表）。
final calendarTaskIndexProvider = Provider<Map<DateTime, List<Task>>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
  final index = <DateTime, List<Task>>{};
  for (final task in tasks) {
    final due = task.dueDate;
    if (due == null) continue;
    final day = DateTime(due.year, due.month, due.day);
    index.putIfAbsent(day, () => []).add(task);
  }
  return index;
}, name: 'calendarTaskIndexProvider');

/// 选中日任务列表。
final selectedDayTasksProvider = Provider.family<List<Task>, DateTime>((
  ref,
  selectedDate,
) {
  final index = ref.watch(calendarTaskIndexProvider);
  final day = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  return index[day] ?? const [];
});

// ── Stats ──

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StatsRepository(db);
});

final statsDaysProvider = StateProvider<int>((ref) => 7);

final dailyCompletionsProvider =
    StreamProvider.family<List<DailyCompletion>, int>((ref, days) {
      final repository = ref.watch(statsRepositoryProvider);
      return repository.watchDailyCompletions(days);
    }, name: 'dailyCompletionsProvider');

// ── SyncService ──

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final connectivity = ref.watch(connectivityProvider);
  return SyncService(repository: repository, connectivity: connectivity);
});

// ── NotificationService ──

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── TextParseService ──

final textParseServiceProvider = Provider<TextParseService>((ref) {
  final dio = ref.watch(dioProvider);
  return TextParseService(dio: dio, endpoint: AppConstants.parseTaskEndpoint);
});

// ── TaskCreationOrchestrator ──

final taskCreationOrchestratorProvider = Provider<TaskCreationOrchestrator>((
  ref,
) {
  return TaskCreationOrchestrator(
    repository: ref.watch(taskRepositoryProvider),
    parseService: ref.watch(textParseServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    showSnackbar: createGlobalSnackbar(
      navigatorKey: ref.watch(appNavigatorKeyProvider),
    ),
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

// ── Volcengine Streaming ASR ──

final asrSessionClientProvider = Provider<AsrSessionClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioAsrSessionClient(
    dio: dio,
    endpoint: AppConstants.asrSessionEndpoint,
    headers: AppConstants.supabaseEdgeHeaders,
  );
});

final volcengineStreamingAsrProvider = Provider<VolcengineStreamingAsr>((ref) {
  return VolcengineStreamingAsrService(
    sessionClient: ref.watch(asrSessionClientProvider),
    relayHeaders: AppConstants.supabaseEdgeHeaders,
  );
});

final streamingVoiceSessionProvider = Provider<StreamingVoiceSession>((ref) {
  return LiveStreamingVoiceSession(
    recorder: ref.watch(voiceRecorderProvider),
    asr: ref.watch(volcengineStreamingAsrProvider),
  );
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

/// 登录后预取思源绑定状态；设置页与其它 UI 共用同一份缓存。
final siyuanBindingStatusProvider = FutureProvider<SiyuanBindingStatus>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const SiyuanBindingStatus(isPaired: false);
  }

  final service = ref.read(siyuanPairingServiceProvider);
  try {
    return await service.getBindingStatus().timeout(const Duration(seconds: 8));
  } catch (_) {
    return const SiyuanBindingStatus(isPaired: false, statusLoadFailed: true);
  }
});

// ── FeedbackService ──

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FeedbackService(supabase: supabase, userId: userId);
});
