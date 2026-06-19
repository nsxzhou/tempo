// TempoHeatmapBar — 精力曲线 12 段(对应 prototype PlanView 精力曲线)
// 4 档灰阶:0.04 / 0.14 / 0.32 / 纯黑,底部时间标签 mono 9px

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoHeatmapBar extends StatelessWidget {
  final List<int> levels; // 1-4
  final List<String> times;
  final double height;

  const TempoHeatmapBar({
    super.key,
    required this.levels,
    required this.times,
    this.height = 40,
  });

  Color _colorForLevel(int level) {
    switch (level) {
      case 1:
        return AppTheme.fg.withValues(alpha: 0.04);
      case 2:
        return AppTheme.fg.withValues(alpha: 0.14);
      case 3:
        return AppTheme.fg.withValues(alpha: 0.32);
      case 4:
        return AppTheme.fg;
      default:
        return AppTheme.bgMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            children: [
              for (final lvl in levels) ...[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorForLevel(lvl),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXxxs),
                    ),
                  ),
                ),
                if (lvl != levels.last) const SizedBox(width: 3),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final t in times)
              Text(
                t,
                style: AppTheme.mono(
                  size: 9,
                  color: AppTheme.fgSubtle,
                  letterSpacing: -0.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 4 档图例
class TempoHeatmapLegend extends StatelessWidget {
  const TempoHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '低',
          style: AppTheme.mono(
            size: 9,
            color: AppTheme.fgMuted,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        for (final lvl in const [1, 2, 3, 4]) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _colorForLevel(lvl),
              shape: BoxShape.circle,
            ),
          ),
          if (lvl < 4) const SizedBox(width: 4),
        ],
        const SizedBox(width: 6),
        Text(
          '高',
          style: AppTheme.mono(
            size: 9,
            color: AppTheme.fgMuted,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Color _colorForLevel(int level) {
    switch (level) {
      case 1:
        return AppTheme.fg.withValues(alpha: 0.04);
      case 2:
        return AppTheme.fg.withValues(alpha: 0.14);
      case 3:
        return AppTheme.fg.withValues(alpha: 0.32);
      case 4:
        return AppTheme.fg;
      default:
        return AppTheme.bgMuted;
    }
  }
}
