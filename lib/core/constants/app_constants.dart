// 应用级常量

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ── 应用信息 ──
  static const String appName = 'Tempo';
  static const String appVersion = '0.1.0';

  // ── 路由路径 ──
  static const String routeTasks = '/tasks';
  static const String routeCalendar = '/calendar';
  static const String routeStats = '/stats';
  static const String routeSettings = '/settings';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeTaskDetail = '/tasks/:id';

  // ── 任务来源 ──
  static const String sourceText = 'text';
  static const String sourceVoice = 'voice';

  // ── 任务分类 tag ──
  static const String tagWork = 'work';
  static const String tagLife = 'life';

  // ── 通知 ──
  static const String notificationChannelId = 'tempo_reminders';
  static const String notificationChannelName = 'Tempo 待办提醒';
  static const String notificationChannelDesc = '有日期的待办，在对应日当天早上推送';

  // ── 分页 ──
  static const int defaultPageSize = 20;

  // ── Supabase 配置 ──
  // 解析顺序:运行时 dart-define > .env > 本地 supabase start 兜底。
  // 字段必须为 getter,无法保留 const,因为 dotenv 在启动期才可读。
  static const String _localSupabaseUrl = 'http://127.0.0.1:54321';
  static const String _localAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// Supabase 项目 URL。
  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? _localSupabaseUrl);

  /// Supabase Anon Key(公开密钥,非 service_role key)。
  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? _localAnonKey);

  /// Supabase Edge Function 请求头（Authorization + apikey）。
  static Map<String, String> get supabaseEdgeHeaders => {
    'Authorization': 'Bearer $supabaseAnonKey',
    'apikey': supabaseAnonKey,
  };

  // ── Deep Link ──
  /// Custom URL scheme（方案 B 降级，公开测试前迁移到 Universal Links / App Links）。
  static const String deepLinkScheme = 'tempo';
  static const String deepLinkCallback = 'tempo://login-callback';

  // ── Edge Function 端点 ──
  /// parse-task 统一解析端点（语音 + 文本共用）。
  static String get parseTaskEndpoint =>
      const String.fromEnvironment('TEMPO_PARSE_TASK_ENDPOINT').isNotEmpty
      ? const String.fromEnvironment('TEMPO_PARSE_TASK_ENDPOINT')
      : (dotenv.env['TEMPO_PARSE_TASK_ENDPOINT'] ??
            'http://127.0.0.1:54321/functions/v1/parse-task');

  /// asr-session 流式语音识别会话配置端点。
  static String get asrSessionEndpoint =>
      const String.fromEnvironment('TEMPO_ASR_SESSION_ENDPOINT').isNotEmpty
      ? const String.fromEnvironment('TEMPO_ASR_SESSION_ENDPOINT')
      : (dotenv.env['TEMPO_ASR_SESSION_ENDPOINT'] ??
            'http://127.0.0.1:54321/functions/v1/asr-session');

  /// siyuan-pairing 配对码交换端点。
  static String get siyuanPairingEndpoint =>
      const String.fromEnvironment('TEMPO_SIYUAN_PAIRING_ENDPOINT').isNotEmpty
      ? const String.fromEnvironment('TEMPO_SIYUAN_PAIRING_ENDPOINT')
      : (dotenv.env['TEMPO_SIYUAN_PAIRING_ENDPOINT'] ??
            'http://127.0.0.1:54321/functions/v1/siyuan-pairing');

  // ── SharedPreferences Keys ──
  static const String prefOnboardingCompleted = 'onboarding_completed';
  static const String prefNotificationEnabled = 'notification_enabled';
  static const String prefThemeId = 'theme_id';
  static const String prefBackgroundImagePath = 'background_image_path';
  static const String prefTaskCardColorPrefix = 'task_card_color_';
  static const String prefHeaderColorPrefix = 'header_color_';

  // ── 配对码 ──
  static const int pairingCodeLength = 6;
  static const Duration pairingCodeExpiry = Duration(minutes: 5);
  static const String siyuanStorageKey = 'tempo_siyuan_auth';

  // ── Supabase 表名 ──
  static const String tableTasks = 'tasks';
  static const String tableTaskLists = 'task_lists';
  static const String tableSiyuanPairingCodes = 'siyuan_pairing_codes';
  static const String tableSiyuanBindings = 'siyuan_bindings';
  static const String tableFeedback = 'feedback';

  // ── 默认列表 ──
  static const String defaultListName = 'Inbox';
  static const String defaultListId = 'local-inbox';
}
