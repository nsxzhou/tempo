// ShellScaffold — 底部 4 Tab 自绘容器
// 用 Stack 包裹 child + 绝对定位 TempoTabBar
// TabBar 与 sheet 同步：AnimatedSlide + AnimatedOpacity

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../constants/app_constants.dart';
import '../debug/agent_debug_log.dart';
import '../theme/app_theme.dart';
import '../widgets/tempo/tempo.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static final GlobalKey _tabBarProbeKey = GlobalKey(debugLabel: 'tabBarProbe');

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppConstants.routeTasks)) return 0;
    if (location.startsWith(AppConstants.routeCalendar)) return 1;
    if (location.startsWith(AppConstants.routePlan)) return 2;
    if (location.startsWith(AppConstants.routeSettings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final tabBarVisible = ref.watch(shellTabBarVisibleProvider);
    final paths = const [
      AppConstants.routeTasks,
      AppConstants.routeCalendar,
      AppConstants.routePlan,
      AppConstants.routeSettings,
    ];

  // #region agent log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box =
          _tabBarProbeKey.currentContext?.findRenderObject() as RenderBox?;
      final mq = MediaQuery.of(context);
      if (box != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        final screenH = mq.size.height;
        agentDebugLog(
          location: 'shell_scaffold.dart:postFrame',
          message: 'tab bar layout probe',
          hypothesisId: 'H1',
          data: {
            'tabBarVisible': tabBarVisible,
            'globalDy': topLeft.dy,
            'tabBarHeight': box.size.height,
            'screenHeight': screenH,
            'nearTop': topLeft.dy < 80,
            'nearBottom': topLeft.dy > screenH - box.size.height - 20,
            'safeTop': mq.padding.top,
            'routeIndex': index,
            'routePath': paths[index],
          },
        );
      } else {
        agentDebugLog(
          location: 'shell_scaffold.dart:postFrame',
          message: 'tab bar probe missing render box',
          hypothesisId: 'H1',
          data: {'tabBarVisible': tabBarVisible, 'routeIndex': index},
        );
      }
    });
    // #endregion

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: AppTheme.durationMedium,
              curve: AppTheme.curveOrganic,
              offset: tabBarVisible ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: AppTheme.durationMedium,
                curve: AppTheme.curveOrganic,
                opacity: tabBarVisible ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !tabBarVisible,
                  child: KeyedSubtree(
                    key: _tabBarProbeKey,
                    child: TempoTabBar(currentPath: paths[index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
