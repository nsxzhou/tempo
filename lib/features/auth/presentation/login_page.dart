// ============================================================
// LoginPage — 邮箱 Magic Link 登录页(对齐 Stripe 派设计系统)
// Instrument Serif 'Tempo' logo + mono 副标题 + 主题输入框 + 黑底按钮
// 逻辑保留:邮箱校验 / sendMagicLink / 等待邮件 / 错误提示
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../data/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scaffoldBg = ref.watch(scaffoldBackgroundProvider);
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Serif italic logo
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: t.italicSerif(
                        size: 40,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '智能待办 · 让时间更有节奏',
                      textAlign: TextAlign.center,
                      style: t.mono(
                        size: 11,
                        color: t.fgMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (_emailSent)
                      _WaitingForEmailCard(
                        email: _emailController.text.trim(),
                        onResend: _sendMagicLink,
                      )
                    else ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const ['email'],
                        style: TextStyle(fontSize: 14, color: t.fg),
                        decoration: InputDecoration(
                          labelText: '邮箱地址',
                          labelStyle: TextStyle(fontSize: 12, color: t.fgMuted),
                          prefixIcon: Icon(
                            LucideIcons.mail,
                            size: 16,
                            color: t.fgMuted,
                          ),
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(fontSize: 13, color: t.fgSubtle),
                        ),
                        validator: _validateEmail,
                        onFieldSubmitted: (_) => _sendMagicLink(),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.priorityP0Bg,
                            border: Border.all(
                              color: AppTheme.priorityP0Border,
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.circle_alert,
                                size: 14,
                                color: AppTheme.priorityP0,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.priorityP0,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSending ? null : () => _sendMagicLink(),
                          style: FilledButton.styleFrom(
                            backgroundColor: t.fg,
                            foregroundColor: t.bg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                          ),
                          child: _isSending
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.bg,
                                  ),
                                )
                              : const Text(
                                  '发送登录链接',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入邮箱地址';
    }
    final email = value.trim();
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(email)) {
      return '邮箱格式不正确';
    }
    return null;
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendMagicLink(_emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _emailSent = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = '发送失败：$error';
      });
    }
  }
}

/// 等待邮件点击的提示卡片(主题卡,非 Material Card)。
class _WaitingForEmailCard extends StatelessWidget {
  final String email;
  final VoidCallback onResend;

  const _WaitingForEmailCard({required this.email, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border.all(color: t.borderStrong, width: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: t.bgSubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: t.borderStrong, width: 0.8),
            ),
            child: Icon(LucideIcons.mail_check, size: 22, color: t.fg),
          ),
          const SizedBox(height: 16),
          Text(
            '请检查邮箱',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.fg,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '我们已向 $email 发送了一封登录邮件,请点击邮件中的链接完成登录。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.fgMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onResend,
            icon: Icon(LucideIcons.refresh_cw, size: 14, color: t.fg),
            label: Text(
              '重新发送',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.fg,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: t.borderStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
