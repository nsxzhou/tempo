// ============================================================
// PairingCodeDialog — 配对码展示弹窗 + 5 分钟倒计时
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// 配对码展示弹窗。
///
/// 生成 6 位配对码，显示 5 分钟倒计时。
class PairingCodeDialog extends ConsumerStatefulWidget {
  const PairingCodeDialog({super.key});

  /// 显示配对码弹窗。
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PairingCodeDialog(),
    );
  }

  @override
  ConsumerState<PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends ConsumerState<PairingCodeDialog> {
  String? _code;
  String? _errorMessage;
  bool _isGenerating = true;

  /// 倒计时（秒）。
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(siyuanPairingServiceProvider);
      final code = await service.generateCode();

      if (!mounted) return;

      _remainingSeconds = AppConstants.pairingCodeExpiry.inSeconds;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 0) {
          timer.cancel();
          if (mounted) {
            setState(() => _code = null);
          }
        } else {
          if (mounted) {
            setState(() => _remainingSeconds--);
          }
        }
      });

      setState(() {
        _code = code;
        _isGenerating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '生成配对码失败：$error';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('思源配对码'),
      content: SizedBox(
        width: 300,
        child: _buildContent(),
      ),
      actions: [
        if (_code == null && !_isGenerating)
          TextButton(
            onPressed: _generateCode,
            child: const Text('重新生成'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isGenerating) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Text('正在生成配对码...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
        ],
      );
    }

    if (_code == null) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('配对码已过期', textAlign: TextAlign.center),
          Text('请重新生成', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('在思源插件中输入以下配对码完成绑定：'),
        const SizedBox(height: 24),
        // 配对码显示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            _formatCode(_code!),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 倒计时
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 16, color: AppTheme.warningColor),
            const SizedBox(width: 4),
            Text(
              '有效期剩余 ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 格式化配对码：12 34 56
  String _formatCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 2)} ${code.substring(2, 4)} ${code.substring(4, 6)}';
  }
}
