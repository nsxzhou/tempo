// ============================================================
// SiyuanManageSheet — 思源连接管理 Bottom Sheet
// 重新配对 / 解绑 · TempoSheet 动效 · 对齐设计系统
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/tempo_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../data/siyuan_pairing_service.dart';
import 'siyuan_status_display.dart';

/// 管理 Sheet 返回的操作类型。
enum SiyuanManageAction { rePair, unpair }

class SiyuanManageSheet extends StatelessWidget {
  const SiyuanManageSheet({super.key, required this.status, this.userEmail});

  final SiyuanBindingStatus status;
  final String? userEmail;

  static Future<SiyuanManageAction?> show(
    BuildContext context, {
    required SiyuanBindingStatus status,
    String? userEmail,
  }) {
    return TempoSheet.show<SiyuanManageAction>(
      context: context,
      builder: (_) => SiyuanManageSheet(status: status, userEmail: userEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderStrong,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.priorityP1Bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.priorityP1Border),
                  ),
                  child: const Icon(
                    LucideIcons.link_2,
                    size: 18,
                    color: AppTheme.priorityP1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '思源连接',
                        style: TextStyle(
                          fontFamily: AppTheme.fontSans,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        siyuanManageSheetSubtitle(status),
                        style: TextStyle(
                          fontFamily: AppTheme.fontSans,
                          fontSize: 12,
                          color: t.fgMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(status: status, userEmail: userEmail),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.refresh_cw,
              label: '重新配对',
              onTap: () => Navigator.pop(context, SiyuanManageAction.rePair),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                '若插件已重装，重新配对即可，无需解绑',
                style: t.mono(
                  size: 10,
                  color: t.fgSubtle,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _MenuItem(
              icon: LucideIcons.unlink,
              label: '解绑思源',
              isDestructive: true,
              onTap: () => Navigator.pop(context, SiyuanManageAction.unpair),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.fgMuted,
                side: BorderSide(color: t.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.status, this.userEmail});

  final SiyuanBindingStatus status;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final lines = <String>[];

    if (userEmail != null && userEmail!.isNotEmpty) {
      lines.add('绑定账号 · $userEmail');
    }
    if (status.pairedAt != null) {
      final when = DateFormat('yyyy/M/d HH:mm').format(status.pairedAt!);
      lines.add('绑定时间 · $when');
    }
    if (status.hasSynced && status.lastSyncAt != null) {
      final when = DateFormat('yyyy/M/d HH:mm').format(status.lastSyncAt!);
      lines.add('最近同步 · $when · 导入 ${status.lastImportedCount} 项');
    }
    if (status.pluginVersion != null) {
      lines.add('插件版本 · v${status.pluginVersion}');
    }

    if (lines.isEmpty) {
      lines.add('尚未完成插件侧配对');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.bgSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: t.borderStrong, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(
              lines[i],
              style: t.mono(
                size: 11,
                color: t.fgMuted,
                weight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '插件重装后，选择「重新配对」即可，无需解绑',
            style: t.mono(size: 10, color: t.fgSubtle, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = isDestructive ? AppTheme.errorColor : t.fg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDestructive ? AppTheme.errorColor : t.fgMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevron_right,
                  size: 16,
                  color: isDestructive ? AppTheme.errorColor : t.fgSubtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
