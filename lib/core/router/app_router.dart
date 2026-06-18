import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../features/tasks/presentation/tasks_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/ai_planner/presentation/plan_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import 'shell_scaffold.dart';

/// 应用路由配置
final goRouter = GoRouter(
  initialLocation: AppConstants.routeTasks,
  routes: [
    // ── 主 Shell（底部导航） ──
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: AppConstants.routeTasks,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TasksPage()),
        ),
        GoRoute(
          path: AppConstants.routeCalendar,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarPage()),
        ),
        GoRoute(
          path: AppConstants.routePlan,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PlanPage()),
        ),
        GoRoute(
          path: AppConstants.routeSettings,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),

    // ── 独立页面 ──
    GoRoute(
      path: AppConstants.routeOnboarding,
      builder: (context, state) => const OnboardingPage(),
    ),

    // ── 任务详情 ──
    GoRoute(
      path: AppConstants.routeTaskDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return _TaskDetailPlaceholder(taskId: id);
      },
    ),
  ],
);

/// 任务详情占位（后续在 features/tasks/presentation/ 中实现）
class _TaskDetailPlaceholder extends StatelessWidget {
  final String taskId;
  const _TaskDetailPlaceholder({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: Center(child: Text('Task ID: $taskId')),
    );
  }
}
