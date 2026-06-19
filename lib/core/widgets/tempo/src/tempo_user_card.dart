// TempoUserCard — 设置页用户卡(对应 prototype SettingsView 头部)
// 用户名 + mono 邮箱 + 注销按钮 + 3 列统计

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../theme/app_theme.dart';

class TempoUserStats {
  final String label;
  final String value;
  final bool highlight; // 绿色
  const TempoUserStats({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

class TempoUserCard extends StatelessWidget {
  final String userName;
  final String? badge; // 紫色徽章文案
  final String email;
  final String signOutLabel;
  final List<TempoUserStats> stats;
  final VoidCallback? onSignOut;

  const TempoUserCard({
    super.key,
    required this.userName,
    this.badge,
    required this.email,
    this.signOutLabel = '注销',
    required this.stats,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Stack(
        children: [
          // 右上角柔光
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppTheme.priorityP2.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                _PurpleBadge(label: badge!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: AppTheme.mono(
                              size: 10,
                              color: AppTheme.fgSubtle,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 注销按钮
                    _SignOutButton(label: signOutLabel, onPressed: onSignOut),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: AppTheme.borderSubtle),
                const SizedBox(height: 16),
                // 3 列统计
                Row(
                  children: [
                    for (int i = 0; i < stats.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 32,
                          color: AppTheme.borderSubtle,
                        ),
                      Expanded(
                        child: _StatColumn(stat: stats[i]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurpleBadge extends StatelessWidget {
  final String label;
  const _PurpleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentIndigoBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxs),
        border: Border.all(color: AppTheme.accentIndigoBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.zap,
            size: 9,
            color: AppTheme.accentIndigoFg,
            fill: 0.4,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentIndigo,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _SignOutButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.priorityP0Border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.log_out,
                size: 12,
                color: AppTheme.priorityP0,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.priorityP0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final TempoUserStats stat;
  const _StatColumn({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          style: AppTheme.mono(
            size: 20,
            weight: FontWeight.w700,
            color: stat.highlight ? AppTheme.success : AppTheme.fg,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label.toUpperCase(),
          style: AppTheme.mono(
            size: 9,
            weight: FontWeight.w700,
            color: AppTheme.fgSubtle,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
