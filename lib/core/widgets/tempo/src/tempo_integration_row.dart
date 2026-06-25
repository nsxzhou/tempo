// TempoIntegrationRow — 思源 / 系统日历集成行(对应 prototype SettingsView)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tempo_theme_extension.dart';
import 'tempo_glass_surface.dart';
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
    final t = context.tokens;
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
                      style: t.mono(
                        size: 10,
                        color: t.fgSubtle,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              TempoPillBadge(label: badgeLabel, kind: badgeKind, fontSize: 10),
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
    final t = context.tokens;
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
                  color: t.bgMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.borderStrong, width: 0.8),
                ),
                child: Icon(icon, size: 14, color: t.fgSecondary),
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
                      style: t.mono(
                        size: 10,
                        color: t.fgSubtle,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// 分组卡片容器(对应 prototype rounded-2xl 容器)
class TempoSettingsGroup extends ConsumerWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? dividerColor;

  const TempoSettingsGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 16),
    this.backgroundColor,
    this.borderColor,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return TempoGlassSurface(
      margin: margin,
      fillColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 60),
                height: 0.5,
                color: dividerColor ?? t.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

/// 兼容旧名(避免 breaking)
typedef TempoIntegrationCard = TempoSettingsGroup;
