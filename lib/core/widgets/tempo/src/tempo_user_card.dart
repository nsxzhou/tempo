// TempoUserCard — 设置页用户卡(Option A: 极简纯文字)
// mono 邮箱 + 灰色注销文字链接 + 3 列统计

import 'package:flutter/material.dart';

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
  final String email;
  final String signOutLabel;
  final List<TempoUserStats> stats;
  final VoidCallback? onSignOut;

  const TempoUserCard({
    super.key,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  email,
                  style: AppTheme.mono(
                    size: 12,
                    color: AppTheme.fg,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // 灰色文字链接
              GestureDetector(
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Text(
                    signOutLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.fgSubtle,
                    ),
                  ),
                ),
              ),
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
