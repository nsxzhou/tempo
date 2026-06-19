// ShellScaffold — 底部 4 Tab 自绘容器
// 用 Stack 包裹 child + 绝对定位 TempoTabBar
// 替换原 Material NavigationBar
// 顶部状态栏改用系统原生 + SafeArea(不再自绘 TempoStatusBar)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/tempo/tempo.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppConstants.routeTasks)) return 0;
    if (location.startsWith(AppConstants.routeCalendar)) return 1;
    if (location.startsWith(AppConstants.routePlan)) return 2;
    if (location.startsWith(AppConstants.routeSettings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    // 构造一条伪 path 给 TempoTabBar 用
    final paths = const [
      AppConstants.routeTasks,
      AppConstants.routeCalendar,
      AppConstants.routePlan,
      AppConstants.routeSettings,
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          // TabBar 浮在底部
          TempoTabBar(currentPath: paths[index]),
        ],
      ),
    );
  }
}
