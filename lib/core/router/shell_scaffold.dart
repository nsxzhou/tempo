// ShellScaffold — 底部 3 Tab 自绘容器
// 用 Stack 包裹 child + 绝对定位 TempoTabBar
// TabBar 与 sheet 同步：AnimatedSlide + AnimatedOpacity
//
// 性能：详情页是顶层路由（root navigator），push 时全屏 Scaffold 自然覆盖
// Shell 的 child。TabBar 显隐由 _TabBarLayer 内部 ListenableBuilder 跟随
// routerDelegate 重建——重建范围被限制在 TabBar 子树，整个 Shell 与 child
// 不再跟随路由变动重建。通知点击 push 前通过 taskDetailOverlayProvider
// 同步置 true，避免滑入期间 tab bar 透出。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../theme/theme_manager.dart';
import '../widgets/tempo/tempo.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  int? _lastShellIndex;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppConstants.routeTasks)) return 0;
    if (location.startsWith(AppConstants.routeCalendar)) return 1;
    if (location.startsWith(AppConstants.routeSettings)) return 2;
    return 0;
  }

  void _dismissShellModals(BuildContext context) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    navigator.popUntil((route) {
      if (route.isFirst) return true;
      return route is! PopupRoute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    if (_lastShellIndex != null && _lastShellIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dismissShellModals(context);
      });
    }
    _lastShellIndex = index;

    const paths = [
      AppConstants.routeTasks,
      AppConstants.routeCalendar,
      AppConstants.routeSettings,
    ];

    return Scaffold(
      backgroundColor: ref.watch(scaffoldBackgroundProvider),
      body: Stack(
        children: [
          // child 不被 Offstage/IgnorePointer 包裹：详情页作为顶层路由 push
          // 在 root navigator，全屏 Scaffold 自然覆盖 Shell，无需手动隐藏。
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TabBarLayer(
              currentPath: paths[index],
              tabBarVisible: ref.watch(shellTabBarVisibleProvider),
              overlayActive: ref.watch(taskDetailOverlayProvider),
              router: GoRouter.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// TabBar 容器层：根据 root 路由 isDetail / overlay / tabBarVisible 计算显隐。
///
/// 内部用 ListenableBuilder(routerDelegate) 把路由变动引起的重建限制在本
/// 子树；Shell 与 child 不随之重建。isDetail 从 routerDelegate 的
/// currentConfiguration 读取（Shell 层的 GoRouterState 仅反映 tab 路由，
/// 无法感知顶层详情页 push）。
class _TabBarLayer extends StatelessWidget {
  final String currentPath;
  final bool tabBarVisible;
  final bool overlayActive;
  final GoRouter router;

  const _TabBarLayer({
    required this.currentPath,
    required this.tabBarVisible,
    required this.overlayActive,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final rootPath = router.routerDelegate.currentConfiguration.uri.path;
        final isDetail = AppConstants.isTaskDetailLocation(rootPath);
        final hidden = isDetail || overlayActive || !tabBarVisible;
        final duration = (isDetail || overlayActive)
            ? Duration.zero
            : AppTheme.durationMedium;

        return AnimatedSlide(
          duration: duration,
          curve: AppTheme.curveOrganic,
          offset: hidden ? const Offset(0, 1) : Offset.zero,
          child: AnimatedOpacity(
            duration: duration,
            curve: AppTheme.curveOrganic,
            opacity: hidden ? 0 : 1,
            child: IgnorePointer(
              ignoring: hidden,
              child: TempoTabBar(currentPath: currentPath),
            ),
          ),
        );
      },
    );
  }
}
