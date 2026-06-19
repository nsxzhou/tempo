// TempoIntegrationRow — 思源 / 系统日历集成行(对应 prototype SettingsView)

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../theme/app_theme.dart';
import 'tempo_pill_badge.dart';

class TempoIntegrationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconBorder;
  final String title;
  final String subtitle;
  final TempoBadgeKind badgeKind;
  final String badgeLabel;
  final VoidCallback? onTap;

  const TempoIntegrationRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBorder,
    required this.title,
    required this.subtitle,
    required this.badgeKind,
    required this.badgeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconBorder, width: 0.8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.mono(
                        size: 10,
                        color: AppTheme.fgSubtle,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              TempoPillBadge(
                label: badgeLabel,
                kind: badgeKind,
                fontSize: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 带 lucide 图标前缀的设置项(对应 prototype 个性化偏好)
class TempoPreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TempoPreferenceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderStrong, width: 0.8),
                ),
                child: Icon(icon, size: 14, color: AppTheme.fgSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.mono(
                        size: 10,
                        color: AppTheme.fgSubtle,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// 分组卡片容器(对应 prototype rounded-2xl 容器)
class TempoSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  const TempoSettingsGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 60),
                height: 0.5,
                color: AppTheme.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

/// 兼容旧名(避免 breaking)
typedef TempoIntegrationCard = TempoSettingsGroup;
