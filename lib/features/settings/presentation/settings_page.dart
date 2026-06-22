// ============================================================
// SettingsPage — 设置页(Stripe 派 1:1 还原 prototype SettingsView.tsx)
// 顶部 TempoUserCard(邮箱 + 3 列实时统计 + 注销)
// 外部集成与同步:思源 / 系统日历
// 个性化偏好:通知 / AI 排程 / 关于
// 业务:通知开关、注销、登出保留;统计从 taskListProvider 实时计算
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tempo/tempo.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadSettings());
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationEnabled =
          prefs.getBool(AppConstants.prefNotificationEnabled) ?? true;
    });
  }

  void _refreshSiyuanStatus() {
    ref.invalidate(siyuanBindingStatusProvider);
  }

  SiyuanBindingStatus _displaySiyuanStatus(AsyncValue<SiyuanBindingStatus> async) {
    return async.valueOrNull ?? const SiyuanBindingStatus(isPaired: false);
  }

  String _siyuanSubtitle(SiyuanBindingStatus status) {
    if (status.isPaired && status.hasSynced && status.lastSyncAt != null) {
      final when = DateFormat('M月d日 HH:mm').format(status.lastSyncAt!);
      return '最近同步：$when · 导入 ${status.lastImportedCount} 项';
    }
    if (status.isPaired) {
      return '已绑定 · 尚未导入任务';
    }
    if (status.hasPendingCode) {
      return '配对码已生成，请在思源插件中输入';
    }
    return '在思源插件中输入配对码完成绑定';
  }

  ({TempoBadgeKind kind, String label}) _siyuanBadge(SiyuanBindingStatus status) {
    if (status.isPaired && status.hasSynced) {
      return (kind: TempoBadgeKind.success, label: '已连通');
    }
    if (status.isPaired) {
      return (kind: TempoBadgeKind.tag, label: '已绑定');
    }
    if (status.hasPendingCode) {
      return (kind: TempoBadgeKind.neutral, label: '待配对');
    }
    return (kind: TempoBadgeKind.neutral, label: '未启用');
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = ref.watch(currentUserEmailProvider);
    final emailText = userEmail ?? '未登录';
    final tasksAsync = ref.watch(taskListProvider);
    final siyuanStatusAsync = ref.watch(siyuanBindingStatusProvider);
    final siyuanStatus = _displaySiyuanStatus(siyuanStatusAsync);

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
                    subtitle: _siyuanSubtitle(siyuanStatus),
                    badgeKind: _siyuanBadge(siyuanStatus).kind,
                    badgeLabel: _siyuanBadge(siyuanStatus).label,
                    onTap: () => _handleSiyuanTap(siyuanStatus),
                  ),
                  TempoIntegrationRow(
                    icon: LucideIcons.calendar_days,
                    iconColor: AppTheme.priorityP2,
                    iconBg: AppTheme.priorityP2Bg,
                    iconBorder: AppTheme.priorityP2Border,
                    title: '本地系统日历订阅',
                    subtitle: '即将推出 · 同步系统日历事件',
                    badgeKind: TempoBadgeKind.neutral,
                    badgeLabel: 'COMING SOON',
                    onTap: () {
                      TempoSnackbar.show(
                        context,
                        message: '系统日历同步即将推出，敬请期待',
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
                    title: '任务到期提醒',
                    subtitle: '有具体时间的任务，到期前 15 分钟与到期时推送',
                    trailing: Switch(
                      value: _notificationEnabled,
                      onChanged: _toggleNotification,
                      activeThumbColor: AppTheme.bg,
                      activeTrackColor: AppTheme.fg,
                      inactiveThumbColor: AppTheme.fgSubtle,
                      inactiveTrackColor: AppTheme.bgMuted,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TempoPreferenceRow(
                    icon: LucideIcons.sliders_horizontal,
                    title: 'AI 排程解析偏好',
                    subtitle: '即将推出 · AI 智能排期',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgMuted,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXxs),
                      ),
                      child: Text(
                        '即将推出',
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
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.setRemindersEnabled(value);
    if (value) {
      await notificationService.requestPermissions();
      final tasks = ref.read(taskListProvider).valueOrNull ?? [];
      await notificationService.rescheduleAllTasks(tasks);
    }
  }

  Future<void> _handleSiyuanTap(SiyuanBindingStatus status) async {
    if (status.isPaired || status.hasPendingCode) {
      await _showSiyuanMenu();
    } else {
      await PairingCodeDialog.show(context);
      _refreshSiyuanStatus();
    }
  }

  Future<void> _showSiyuanMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          boxShadow: [
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
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderStrong,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSiyuanMenuItem(ctx, LucideIcons.unlink, '解绑思源', 'unpair'),
              const SizedBox(height: 4),
              _buildSiyuanMenuItem(ctx, LucideIcons.refresh_cw, '重新生成配对码', 'pair'),
            ],
          ),
        ),
      ),
    );
    if (action == 'pair' && mounted) {
      await PairingCodeDialog.show(context);
      _refreshSiyuanStatus();
    } else if (action == 'unpair' && mounted) {
      await ref.read(siyuanPairingServiceProvider).clearBinding();
      if (!mounted) return;
      _refreshSiyuanStatus();
      TempoSnackbar.show(
        context,
        message: '已解除 App 侧绑定，请在思源插件中点击解绑',
      );
    }
  }

  Widget _buildSiyuanMenuItem(
    BuildContext ctx,
    IconData icon,
    String label,
    String action,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, action),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.fgMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontSans,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await TempoConfirmDialog.show(
      context,
      title: '注销',
      message: '确定要登出吗?本地数据将保留,重新登录后可继续同步。',
      confirmLabel: '登出',
      isDestructive: true,
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
