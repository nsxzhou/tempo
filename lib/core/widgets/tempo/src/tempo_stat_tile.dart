// TempoStatTile — 计划页 3 列统计块(对应 prototype AI 智能排期卡)

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoStatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight; // 绿色
  final EdgeInsetsGeometry padding;

  const TempoStatTile({
    super.key,
    required this.value,
    required this.label,
    this.highlight = false,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.mono(
              size: 18,
              weight: FontWeight.w500,
              color: highlight ? AppTheme.success : AppTheme.fg,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTheme.mono(
              size: 9,
              weight: FontWeight.w500,
              color: AppTheme.fgMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
