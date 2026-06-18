// ============================================================
// LoginPage — 邮箱 Magic Link 登录页
// 用户输入邮箱 → 发送 Magic Link → 等待邮件点击 → Deep Link 唤起 → 自动登录
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_service.dart';

/// 登录页：邮箱输入 + 发送 Magic Link + 等待状态。
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / 标题
                    Icon(
                      Icons.checklist_rounded,
                      size: 72,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '智能待办 · 让时间更有节奏',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 48),

                    if (_emailSent) ...[
                      _WaitingForEmailCard(
                        email: _emailController.text.trim(),
                        onResend: _sendMagicLink,
                      ),
                    ] else ...[
                      // 邮箱输入框
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const ['email'],
                        decoration: const InputDecoration(
                          labelText: '邮箱地址',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'you@example.com',
                        ),
                        validator: _validateEmail,
                        onFieldSubmitted: (_) => _sendMagicLink(),
                      ),
                      const SizedBox(height: 16),

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 发送按钮
                      FilledButton(
                        onPressed: _isSending ? null : () => _sendMagicLink(),
                        child: _isSending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('发送登录链接'),
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

/// 等待邮件点击的提示卡片。
class _WaitingForEmailCard extends StatelessWidget {
  final String email;
  final VoidCallback onResend;

  const _WaitingForEmailCard({
    required this.email,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '请检查邮箱',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '我们已向 $email 发送了一封登录邮件，请点击邮件中的链接完成登录。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onResend,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新发送'),
            ),
          ],
        ),
      ),
    );
  }
}
