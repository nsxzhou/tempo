import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

/// 底部导航 Shell 容器
///
/// 包裹 Tasks / Calendar / Plan / Settings 四个主 Tab 页面。
class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      path: AppConstants.routeTasks,
      icon: Icons.checklist_outlined,
      activeIcon: Icons.checklist,
      label: '待办',
    ),
    _TabItem(
      path: AppConstants.routeCalendar,
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: '日历',
    ),
    _TabItem(
      path: AppConstants.routePlan,
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: '计划',
    ),
    _TabItem(
      path: AppConstants.routeSettings,
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return _tabs.indexWhere((t) => location.startsWith(t.path));
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
