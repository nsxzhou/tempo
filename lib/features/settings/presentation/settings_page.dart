// ============================================================
// SettingsPage — 完整设置页（账户/思源同步/通知/反馈/关于）
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/siyuan_pairing_service.dart';
import 'feedback_dialog.dart';
import 'pairing_code_dialog.dart';

/// 设置页：账户/思源同步/通知/反馈/关于。
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
    setState(() {
      _notificationEnabled =
          prefs.getBool(AppConstants.prefNotificationEnabled) ?? true;
    });

    // 检查配对码状态
    final pairingService = ref.read(siyuanPairingServiceProvider);
    final code = await pairingService.getActiveCode();
    if (mounted) {
      setState(() => _activePairingCode = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── 账户 ──
          _SectionTitle('账户'),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(userEmail ?? '未登录'),
                trailing: FilledButton.tonal(
                  onPressed: () => _signOut(context),
                  child: const Text('登出'),
                ),
              ),
            ],
          ),

          // ── 思源同步 ──
          _SectionTitle('思源同步'),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('思源笔记绑定'),
                subtitle: Text(
                  _activePairingCode?.isValid == true
                      ? '有有效配对码'
                      : _activePairingCode?.isUsed == true
                          ? '已绑定'
                          : '未绑定',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'pair') {
                      PairingCodeDialog.show(context);
                    } else if (value == 'unpair') {
                      _showUnpairConfirm(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pair',
                      child: Text('生成配对码'),
                    ),
                    if (_activePairingCode != null)
                      const PopupMenuItem(
                        value: 'unpair',
                        child: Text('解绑'),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── 通知 ──
          _SectionTitle('通知'),
          _SettingCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('到期提醒'),
                subtitle: const Text('任务到期前 15 分钟和到期时通知'),
                value: _notificationEnabled,
                onChanged: (value) async {
                  setState(() => _notificationEnabled = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                      AppConstants.prefNotificationEnabled, value);
                },
              ),
            ],
          ),

          // ── 反馈 ──
          _SectionTitle('反馈'),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('提交反馈'),
                subtitle: const Text('报告 Bug 或提出建议'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => FeedbackDialog.show(context),
              ),
            ],
          ),

          // ── 关于 ──
          _SectionTitle('关于'),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                trailing: Text(
                  'Tempo v${AppConstants.appVersion}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 登出。
  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登出'),
        content: const Text('确定要登出吗？本地数据将保留，重新登录后可继续同步。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      context.go(AppConstants.routeLogin);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登出失败：$error')),
      );
    }
  }

  /// 解绑思源。
  Future<void> _showUnpairConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解绑思源'),
        content: const Text('确定要解绑思源笔记吗？需要重新配对才能继续导入任务。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('解绑'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 思源解绑在插件端操作（清除 localStorage）
    // App 端只需更新 UI
    setState(() => _activePairingCode = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在思源插件中点击解绑按钮完成解绑')),
    );
  }
}

/// 分区标题。
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

/// 设置卡片容器。
class _SettingCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}
