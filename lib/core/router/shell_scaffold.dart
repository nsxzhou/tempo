// ShellScaffold — 底部 4 Tab 自绘容器
// 用 Stack 包裹 child + 绝对定位 TempoTabBar
// TabBar 与 sheet 同步：AnimatedSlide + AnimatedOpacity

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
    if (location.startsWith(AppConstants.routeStats)) return 2;
    if (location.startsWith(AppConstants.routeSettings)) return 3;
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

    final tabBarVisible = ref.watch(shellTabBarVisibleProvider);
    const paths = [
      AppConstants.routeTasks,
      AppConstants.routeCalendar,
      AppConstants.routeStats,
      AppConstants.routeSettings,
    ];

    return Scaffold(
      backgroundColor: ref.watch(scaffoldBackgroundProvider),
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
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
                  child: TempoTabBar(currentPath: paths[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
