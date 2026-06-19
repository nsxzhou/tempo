// ============================================================
// SettingsPage — 设置页(Stripe 派 1:1 还原 prototype SettingsView.tsx)
// 顶部 TempoUserCard(邮箱 + 3 列实时统计 + 注销)
// 外部集成与同步:思源 / 系统日历
// 个性化偏好:通知 / AI 排程 / 关于
// 业务:通知开关、注销、登出保留;统计从 taskListProvider 实时计算
// ============================================================

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../../tasks/domain/task.dart';
import '../data/siyuan_pairing_service.dart';
import 'feedback_dialog.dart';
import 'pairing_code_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationEnabled = true;
  PairingCode? _activePairingCode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationEnabled =
            prefs.getBool(AppConstants.prefNotificationEnabled) ?? true;
      });
    }
    final pairingService = ref.read(siyuanPairingServiceProvider);
    final code = await pairingService.getActiveCode();
    if (mounted) {
      setState(() => _activePairingCode = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = ref.watch(currentUserEmailProvider);
    final emailText = userEmail ?? '未登录';
    final tasksAsync = ref.watch(taskListProvider);

    final stats = tasksAsync.maybeWhen(
      data: (tasks) {
        final completed = tasks.where((t) => t.isCompleted).length;
        final pending = tasks.where((t) => !t.isCompleted).length;
        final voice = tasks
            .where((t) => t.creationSource == AppConstants.sourceVoice)
            .length;
        return [
          TempoUserStats(label: '累计完成', value: '$completed 项'),
          TempoUserStats(label: '待办进行', value: '$pending 项'),
          TempoUserStats(
            label: '语音创建',
            value: '$voice 项',
            highlight: true,
          ),
        ];
      },
      orElse: () => const [
        TempoUserStats(label: '累计完成', value: '0 项'),
        TempoUserStats(label: '待办进行', value: '0 项'),
        TempoUserStats(label: '语音创建', value: '0 项', highlight: true),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的',
                      style: AppTheme.sansSemibold(
                        size: 32,
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // 用户卡
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TempoUserCard(
                  email: emailText,
                  stats: stats,
                  onSignOut: () => _signOut(),
                ),
              ),
              const SizedBox(height: 12),

              // 外部集成与同步
              const TempoSectionHeader(
                label: '外部集成与同步',
                padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              ),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                children: [
                  TempoIntegrationRow(
                    icon: LucideIcons.link_2,
                    iconColor: AppTheme.priorityP1,
                    iconBg: AppTheme.priorityP1Bg,
                    iconBorder: AppTheme.priorityP1Border,
                    title: '思源外部笔记 Petal 连接',
                    subtitle: '2 分钟前已本地自动增量联动',
                    badgeKind: _activePairingCode?.isValid == true
                        ? TempoBadgeKind.success
                        : (_activePairingCode?.isUsed == true
                            ? TempoBadgeKind.tag
                            : TempoBadgeKind.neutral),
                    badgeLabel: _activePairingCode?.isValid == true
                        ? '已连通'
                        : (_activePairingCode?.isUsed == true
                            ? '已绑定'
                            : '未启用'),
                    onTap: () => _handleSiyuanTap(),
                  ),
                  TempoIntegrationRow(
                    icon: LucideIcons.calendar_days,
                    iconColor: AppTheme.priorityP2,
                    iconBg: AppTheme.priorityP2Bg,
                    iconBorder: AppTheme.priorityP2Border,
                    title: '本地系统日历订阅',
                    subtitle: '已监听 13 项重要业务冲突日程',
                    badgeKind: TempoBadgeKind.active,
                    badgeLabel: 'ACTIVE',
                    onTap: () {
                      TempoSnackbar.show(
                        context,
                        message: '系统日历服务正在稳定守候中',
                      );
                    },
                  ),
                ],
              ),

              // 个性化偏好
              const TempoSectionHeader(
                label: '个性化偏好',
                padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              ),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                children: [
                  TempoPreferenceRow(
                    icon: LucideIcons.bell,
                    title: '桌面高频提醒',
                    subtitle: '任务倒计时与 AI 周期精力诊断',
                    trailing: SizedBox(
                      width: 34,
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CupertinoSwitch(
                          value: _notificationEnabled,
                          onChanged: _toggleNotification,
                          activeTrackColor: AppTheme.fg,
                        ),
                      ),
                    ),
                  ),
                  TempoPreferenceRow(
                    icon: LucideIcons.sliders_horizontal,
                    title: 'AI 排程解析偏好',
                    subtitle: '排期策略优化与长文总结合并',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgMuted,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXxs),
                      ),
                      child: Text(
                        '锌版/Zinc',
                        style: AppTheme.mono(
                          size: 9,
                          color: AppTheme.fgMuted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TempoPreferenceRow(
                    icon: LucideIcons.info,
                    title: '关于 Tempo MVP',
                    subtitle: 'Stripe 精致排版工艺学 V2.0.0',
                    trailing: Text(
                      'v2.0.0',
                      style: AppTheme.mono(
                        size: 9,
                        color: AppTheme.fgMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      TempoSnackbar.show(
                        context,
                        message: 'Tempo — 智能同步时间规划大师',
                      );
                    },
                  ),
                ],
              ),

              // 反馈入口
              const SizedBox(height: 8),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  TempoPreferenceRow(
                    icon: LucideIcons.message_square,
                    title: '提交反馈',
                    subtitle: '报告 Bug 或提出建议',
                    trailing: const Icon(
                      LucideIcons.chevron_right,
                      size: 14,
                      color: AppTheme.fgMuted,
                    ),
                    onTap: () => FeedbackDialog.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => _notificationEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotificationEnabled, value);
  }

  Future<void> _handleSiyuanTap() async {
    if (_activePairingCode?.isValid == true) {
      _showSiyuanMenu();
    } else {
      PairingCodeDialog.show(context);
    }
  }

  Future<void> _showSiyuanMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.unlink),
              title: const Text('解绑思源'),
              onTap: () => Navigator.pop(ctx, 'unpair'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.refresh_cw),
              title: const Text('重新生成配对码'),
              onTap: () => Navigator.pop(ctx, 'pair'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'pair' && mounted) {
      unawaited(PairingCodeDialog.show(context));
    } else if (action == 'unpair' && mounted) {
      setState(() => _activePairingCode = null);
      TempoSnackbar.show(
        context,
        message: '请在思源插件中点击解绑按钮完成解绑',
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.borderStrong, width: 0.8),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '注销',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.fg,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '确定要登出吗?本地数据将保留,重新登录后可继续同步。',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.fgMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.fgMuted,
                        side: const BorderSide(color: AppTheme.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.priorityP0,
                        foregroundColor: AppTheme.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '登出',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      context.go(AppConstants.routeLogin);
    } catch (e) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '登出失败:$e');
    }
  }
}
