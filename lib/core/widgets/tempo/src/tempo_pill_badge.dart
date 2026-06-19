// TempoPillBadge — 圆 Pill 徽章
// 对应 prototype 全部 px-1.5 py-0.5 rounded-full border 10px 标签
// 支持 priority / success / custom 三种样式

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// 徽章语义类型
enum TempoBadgeKind {
  p0,
  p1,
  p2,
  p3,
  success,
  active, // 黑底白字 (ACTIVE 标签)
  neutral, // 灰底灰边
  tag, // @tag 灰底
  error, // 红色细边
}

class TempoPillBadge extends StatelessWidget {
  final String label;
  final TempoBadgeKind kind;
  final IconData? icon;
  final bool uppercase;
  final bool serif;
  final double fontSize;

  const TempoPillBadge({
    super.key,
    required this.label,
    this.kind = TempoBadgeKind.neutral,
    this.icon,
    this.uppercase = true,
    this.serif = false,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final style = serif
        ? AppTheme.italicSerif(size: fontSize, color: colors.fg)
        : AppTheme.mono(
            size: fontSize,
            weight: FontWeight.w600,
            color: colors.fg,
            letterSpacing: 0.4,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: colors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize, color: colors.fg),
            const SizedBox(width: 3),
          ],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: style,
          ),
        ],
      ),
    );
  }

  _BadgeColors _resolveColors() {
    switch (kind) {
      case TempoBadgeKind.p0:
        return _BadgeColors(
          fg: AppTheme.priorityP0,
          bg: AppTheme.priorityP0Bg,
          border: AppTheme.priorityP0Border,
        );
      case TempoBadgeKind.p1:
        return _BadgeColors(
          fg: AppTheme.priorityP1,
          bg: AppTheme.priorityP1Bg,
          border: AppTheme.priorityP1Border,
        );
      case TempoBadgeKind.p2:
        return _BadgeColors(
          fg: AppTheme.priorityP2,
          bg: AppTheme.priorityP2Bg,
          border: AppTheme.priorityP2Border,
        );
      case TempoBadgeKind.p3:
        return _BadgeColors(
          fg: AppTheme.priorityP3,
          bg: AppTheme.priorityP3Bg,
          border: AppTheme.priorityP3Border,
        );
      case TempoBadgeKind.success:
        return _BadgeColors(
          fg: AppTheme.success,
          bg: AppTheme.successBg,
          border: AppTheme.successBorder,
        );
      case TempoBadgeKind.active:
        return _BadgeColors(
          fg: AppTheme.bg,
          bg: AppTheme.fg,
          border: AppTheme.fg,
        );
      case TempoBadgeKind.tag:
        return _BadgeColors(
          fg: AppTheme.fgMuted,
          bg: AppTheme.bgMuted,
          border: AppTheme.borderStrong,
        );
      case TempoBadgeKind.error:
        return const _BadgeColors(
          fg: AppTheme.priorityP0,
          bg: AppTheme.priorityP0Bg,
          border: AppTheme.priorityP0Border,
        );
      case TempoBadgeKind.neutral:
        return _BadgeColors(
          fg: AppTheme.fgMuted,
          bg: AppTheme.bg,
          border: AppTheme.borderStrong,
        );
    }
  }
}

class _BadgeColors {
  final Color fg;
  final Color bg;
  final Color border;
  const _BadgeColors({required this.fg, required this.bg, required this.border});
}
