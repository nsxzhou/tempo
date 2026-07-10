// ============================================================
// SettingsPage — 设置页(Stripe 派 1:1 还原 prototype SettingsView.tsx)
// 顶部 TempoUserCard(邮箱 + 注销)
// 外部集成与同步:思源 / 系统日历
// 个性化偏好:通知 / 主题
// 业务:通知开关、注销、登出保留
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import 'widgets/theme_settings_section.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../data/siyuan_pairing_service.dart';
import 'feedback_dialog.dart';
import 'pairing_code_dialog.dart';
import 'siyuan_manage_sheet.dart';
import 'siyuan_status_display.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  bool _notificationEnabled = true;

  @override
  bool get wantKeepAlive => true;

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

  SiyuanBindingStatus _displaySiyuanStatus(
    AsyncValue<SiyuanBindingStatus> async,
  ) {
    return async.valueOrNull ?? const SiyuanBindingStatus(isPaired: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userEmail = ref.watch(currentUserEmailProvider);
    final emailText = userEmail ?? '未登录';
    final siyuanStatusAsync = ref.watch(siyuanBindingStatusProvider);
    final siyuanStatus = _displaySiyuanStatus(siyuanStatusAsync);

    final tokens = context.tokens;
    final scaffoldBg = ref.watch(scaffoldBackgroundProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
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
                      style: tokens.sansSemibold(
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
                  onSignOut: () => _signOut(),
                ),
              ),
              const SizedBox(height: 12),

              // 外部集成与同步
              TempoSectionHeader(
                label: '外部集成与同步',
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                color: tokens.fgMuted,
              ),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                borderColor: tokens.borderStrong,
                dividerColor: tokens.borderSubtle,
                children: [
                  TempoIntegrationRow(
                    icon: LucideIcons.link_2,
                    iconColor: tokens.priorityColor(2),
                    iconBg: tokens.priorityBg(2),
                    iconBorder: tokens.priorityBorder(2),
                    title: '思源外部笔记 Petal 连接',
                    subtitle: siyuanIntegrationSubtitle(siyuanStatus),
                    badgeKind: siyuanIntegrationBadge(siyuanStatus).kind,
                    badgeLabel: siyuanIntegrationBadge(siyuanStatus).label,
                    onTap: () => _handleSiyuanTap(siyuanStatus),
                  ),
                  TempoIntegrationRow(
                    icon: LucideIcons.calendar_days,
                    iconColor: tokens.priorityColor(3),
                    iconBg: tokens.priorityBg(3),
                    iconBorder: tokens.priorityBorder(3),
                    title: '本地系统日历订阅',
                    subtitle: '即将推出 · 同步系统日历事件',
                    badgeKind: TempoBadgeKind.neutral,
                    badgeLabel: 'COMING SOON',
                    onTap: () {
                      TempoSnackbar.show(context, message: '系统日历同步即将推出，敬请期待');
                    },
                  ),
                ],
              ),

              // 个性化偏好
              TempoSectionHeader(
                label: '个性化偏好',
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                color: tokens.fgMuted,
              ),
              const ThemeSettingsSection(),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                borderColor: tokens.borderStrong,
                dividerColor: tokens.borderSubtle,
                children: [
                  TempoPreferenceRow(
                    icon: LucideIcons.bell,
                    title: '待办提醒',
                    subtitle: '具体时间按时提醒，全天任务当天 08:00 提醒',
                    trailing: Switch(
                      value: _notificationEnabled,
                      onChanged: _toggleNotification,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              // 反馈入口
              const SizedBox(height: 8),
              TempoSettingsGroup(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                borderColor: tokens.borderStrong,
                dividerColor: tokens.borderSubtle,
                children: [
                  TempoPreferenceRow(
                    icon: LucideIcons.message_square,
                    title: '提交反馈',
                    subtitle: '报告 Bug 或提出建议',
                    trailing: Icon(
                      LucideIcons.chevron_right,
                      size: 14,
                      color: tokens.fgMuted,
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
    final remoteNotificationService = ref.read(
      remoteNotificationServiceProvider,
    );
    await notificationService.setRemindersEnabled(value);
    final registered = await remoteNotificationService.setRemindersEnabled(
      value,
    );
    ref.read(remoteNotificationRegisteredProvider.notifier).state = registered;
    if (value) {
      await notificationService.requestPermissions();
      final tasks = ref.read(taskListProvider).valueOrNull ?? [];
      final completions = ref.read(taskCompletionsProvider).valueOrNull ?? [];
      final exceptions =
          ref.read(taskRecurrenceExceptionsProvider).valueOrNull ?? [];
      await notificationService.rescheduleAllTasks(
        tasks,
        completions: completions,
        exceptions: exceptions,
      );
    }
  }

  Future<void> _handleSiyuanTap(SiyuanBindingStatus status) async {
    if (status.statusLoadFailed) {
      _refreshSiyuanStatus();
      TempoSnackbar.show(context, message: '正在重新检查思源连接状态');
      return;
    }

    if (!status.isPaired) {
      await PairingCodeDialog.show(
        context,
        existingCode: status.pendingCode?.isValid == true
            ? status.pendingCode
            : null,
      );
      _refreshSiyuanStatus();
      return;
    }

    final userEmail = ref.read(currentUserEmailProvider);
    final action = await SiyuanManageSheet.show(
      context,
      status: status,
      userEmail: userEmail,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case SiyuanManageAction.rePair:
        await PairingCodeDialog.show(context);
        _refreshSiyuanStatus();
      case SiyuanManageAction.unpair:
        await _confirmAndUnpairSiyuan();
    }
  }

  Future<void> _confirmAndUnpairSiyuan() async {
    final confirmed = await TempoConfirmDialog.show(
      context,
      title: '解绑思源',
      message:
          '确定解除与思源的连接吗？解绑后需在思源插件中重新输入配对码。'
          '若只是插件重装，可直接选择「重新配对」，无需解绑。',
      confirmLabel: '解绑',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    await ref.read(siyuanPairingServiceProvider).clearBinding();
    if (!mounted) return;
    _refreshSiyuanStatus();
    TempoSnackbar.show(context, message: '已解除 App 侧绑定，请在思源插件中点击解绑');
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
      await ref.read(remoteNotificationServiceProvider).disableCurrentDevice();
      ref.read(remoteNotificationRegisteredProvider.notifier).state = false;
      await ref.read(notificationServiceProvider).cancelAll();
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      context.go(AppConstants.routeLogin);
    } catch (e) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '登出失败:$e');
    }
  }
}
