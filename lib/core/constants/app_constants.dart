// 应用级常量

class AppConstants {
  AppConstants._();

  // ── 应用信息 ──
  static const String appName = 'Tempo';
  static const String appVersion = '0.1.0';

  // ── 路由路径 ──
  static const String routeHome = '/';
  static const String routeTasks = '/tasks';
  static const String routeCalendar = '/calendar';
  static const String routePlan = '/plan';
  static const String routeSettings = '/settings';
  static const String routeOnboarding = '/onboarding';
  static const String routeTaskDetail = '/tasks/:id';

  // ── 优先级 ──
  static const int priorityNone = 0;
  static const int priorityP0 = 1; // 紧急
  static const int priorityP1 = 2; // 高
  static const int priorityP2 = 3; // 中
  static const int priorityP3 = 4; // 低

  // ── 任务来源 ──
  static const String sourceText = 'text';
  static const String sourceSiyuan = 'siyuan';
  static const String sourceVoice = 'voice';
  static const String sourceAi = 'ai';

  // ── 通知 ──
  static const int reminderBeforeMinutes = 15;

  // ── 分页 ──
  static const int defaultPageSize = 20;
}
