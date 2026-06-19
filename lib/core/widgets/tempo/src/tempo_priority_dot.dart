// TempoPriorityDot — 优先级 3px 小圆点(贯穿任务列表/详情/计划页)

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoPriorityDot extends StatelessWidget {
  final int priority; // 0/1/2/3
  final double size;
  const TempoPriorityDot({super.key, required this.priority, this.size = 6});

  @override
  Widget build(BuildContext context) {
    if (priority == 0) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.priorityColor(priority),
        shape: BoxShape.circle,
      ),
    );
  }
}
