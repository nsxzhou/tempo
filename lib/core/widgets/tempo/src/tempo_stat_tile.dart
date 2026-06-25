// TempoStatTile — 计划页 3 列统计块(对应 prototype AI 智能排期卡)

import 'package:flutter/material.dart';

import '../../../theme/tempo_theme_extension.dart';

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
    final t = context.tokens;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: t.mono(
              size: 18,
              weight: FontWeight.w500,
              color: highlight ? t.success : t.fg,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: t.mono(
              size: 9,
              weight: FontWeight.w500,
              color: t.fgMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
