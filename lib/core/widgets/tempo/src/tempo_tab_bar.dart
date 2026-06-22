// TempoTabBar — 底部 4 Tab 自绘区
// 对应原型 4 Tab 底部导航
// 指示器 spring 200ms · 图标/字重过渡 200ms

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class TempoTabBar extends StatelessWidget {
  final String currentPath;
  const TempoTabBar({super.key, required this.currentPath});

  static const _tabs = <_TabSpec>[
    _TabSpec(
      path: AppConstants.routeTasks,
      icon: LucideIcons.square_check,
      label: '待办',
    ),
    _TabSpec(
      path: AppConstants.routeCalendar,
      icon: LucideIcons.calendar_days,
      label: '日历',
    ),
    _TabSpec(
      path: AppConstants.routePlan,
      icon: LucideIcons.sparkles,
      label: '计划',
    ),
    _TabSpec(
      path: AppConstants.routeSettings,
      icon: LucideIcons.user_round,
      label: '我的',
    ),
  ];

  int get _currentIndex {
    final i = _tabs.indexWhere((t) => currentPath.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = _tabs.length;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          border: Border(
            top: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
          ),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8 + MediaQuery.of(context).padding.bottom,
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / tabCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: AppTheme.durationFast,
                    curve: AppTheme.curveSpring,
                    left: tabWidth * _currentIndex + tabWidth * 0.25,
                    top: 0,
                    width: tabWidth * 0.5,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.fg,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(tabCount, (i) {
                      final tab = _tabs[i];
                      final selected = i == _currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go(tab.path),
                          child: SizedBox(
                            height: 48,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: selected ? 1.0 : 0.92,
                                  duration: AppTheme.durationFast,
                                  curve: AppTheme.curveOrganic,
                                  child: Icon(
                                    tab.icon,
                                    size: 22,
                                    color: selected
                                        ? AppTheme.fg
                                        : AppTheme.fgMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: AppTheme.durationFast,
                                  curve: AppTheme.curveOrganic,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppTheme.fg
                                        : AppTheme.fgMuted,
                                    letterSpacing: -0.1,
                                  ),
                                  child: Text(tab.label),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String path;
  final IconData icon;
  final String label;
  const _TabSpec({required this.path, required this.icon, required this.label});
}
