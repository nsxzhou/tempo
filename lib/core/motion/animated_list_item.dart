// AnimatedListItem / StaggeredReveal — 列表入场 stagger 辅助

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// 单条列表项 fade + slide 入场
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int maxStagger;
  final Duration staggerInterval;
  final String? listKey;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.maxStagger = 8,
    this.staggerInterval = const Duration(milliseconds: 50),
    this.listKey,
  });

  @override
  Widget build(BuildContext context) {
    final delayMs = index.clamp(0, maxStagger - 1) * staggerInterval.inMilliseconds;

    return child
        .animate(key: listKey != null ? ValueKey('$listKey-$index') : null)
        .fadeIn(
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveOrganic,
          delay: Duration(milliseconds: delayMs),
        )
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveOrganic,
          delay: Duration(milliseconds: delayMs),
        );
  }
}

/// 批量 stagger 揭示容器
class StaggeredReveal extends StatelessWidget {
  final List<Widget> children;
  final int maxStagger;
  final Duration staggerInterval;
  final String listKey;

  const StaggeredReveal({
    super.key,
    required this.children,
    required this.listKey,
    this.maxStagger = 8,
    this.staggerInterval = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          AnimatedListItem(
            key: ValueKey('$listKey-item-$i'),
            index: i,
            maxStagger: maxStagger,
            staggerInterval: staggerInterval,
            listKey: listKey,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
