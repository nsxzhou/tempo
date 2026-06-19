// TempoSectionHeader — 分区小标(对应 prototype 区段标题)
// 10px Geist 700 UPPERCASE tracking-widest + 右侧 1px 灰线延伸到边缘

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoSectionHeader extends StatelessWidget {
  final String label;
  final String? trailing;
  final EdgeInsetsGeometry padding;
  final Color color;

  const TempoSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 8),
    this.color = AppTheme.fgMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.mono(
              size: 10,
              weight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: AppTheme.mono(
                size: 10,
                weight: FontWeight.w500,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AppTheme.borderStrong),
          ),
        ],
      ),
    );
  }
}
