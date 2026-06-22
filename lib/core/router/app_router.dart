// ============================================================
// 应用路由配置
// 包含: 路由守卫(auth + onboarding)、Shell 导航、登录页、任务详情页
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/tasks/presentation/tasks_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/ai_planner/presentation/plan_placeholder_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import 'shell_scaffold.dart';

/// 全局 Navigator Key。
///
/// 供非上下文回调（通知点击）使用 showDialog / 导航。
/// 传入 GoRouter 后，其 currentContext 即为路由管理 Navigator 的上下文。
final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'tempo_app');
});

/// GoRouter Provider（使用 Riverpod 管理，支持 auth 状态响应式刷新）。
final routerProvider = Provider<GoRouter>((ref) {
  final navigatorKey = ref.watch(appNavigatorKeyProvider);
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppConstants.routeTasks,
    redirect: (context, state) async {
      // 允许的公共路由（不需要 auth）
      final publicRoutes = [
        AppConstants.routeOnboarding,
        AppConstants.routeLogin,
      ];
      final currentPath = state.matchedLocation;

      // 检查 onboarding 是否完成
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;

      if (!onboardingCompleted && !publicRoutes.contains(currentPath)) {
        return AppConstants.routeOnboarding;
      }

      // 检查 auth 状态
      final session = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = session != null;

      if (!isLoggedIn &&
          !publicRoutes.contains(currentPath) &&
          onboardingCompleted) {
        return AppConstants.routeLogin;
      }

      // 已登录但停留在 login/onboarding → 跳转 tasks
      if (isLoggedIn &&
          (currentPath == AppConstants.routeLogin ||
              currentPath == AppConstants.routeOnboarding)) {
        return AppConstants.routeTasks;
      }

      return null;
    },
    routes: [
      // ── 公共路由（不需要 auth）──
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

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
                const NoTransitionPage(child: PlanPlaceholderPage()),
          ),
          GoRoute(
            path: AppConstants.routeSettings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),

      // ── 任务详情 ──
      GoRoute(
        path: AppConstants.routeTaskDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailPage(taskId: id);
        },
      ),
    ],
  );

  // 当 auth 状态变化时刷新路由守卫
  ref.listen(authStateProvider, (_, __) {
    router.refresh();
  });

  return router;
});
