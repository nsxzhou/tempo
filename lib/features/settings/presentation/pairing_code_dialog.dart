// ============================================================
// PairingCodeDialog — 配对码展示弹窗 + 5 分钟倒计时
// 自定义 Dialog(主题卡) + Geist Mono 大号配对码 + mono 倒计时
// 逻辑保留:generateCode / Timer 倒计时 / 过期处理
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PairingCodeDialog extends ConsumerStatefulWidget {
  const PairingCodeDialog({super.key});

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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderStrong, width: 0.8),
          boxShadow: AppTheme.shadowSm,
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '思源配对码',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.fg,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(LucideIcons.x, size: 16, color: AppTheme.fgMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildBody(),
        const SizedBox(height: 20),
        _buildActions(),
      ],
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.fg,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '正在生成配对码...',
            style: AppTheme.mono(size: 11, color: AppTheme.fgMuted),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.circle_alert,
            color: AppTheme.priorityP0,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.priorityP0, height: 1.4),
          ),
        ],
      );
    }

    if (_code == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer_off, size: 32, color: AppTheme.fgMuted),
          const SizedBox(height: 12),
          const Text(
            '配对码已过期',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.fgSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请重新生成',
            style: AppTheme.mono(size: 10, color: AppTheme.fgMuted),
          ),
        ],
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '在思源插件中输入以下配对码完成绑定',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.fgMuted, height: 1.5),
        ),
        const SizedBox(height: 16),
        // 配对码 Geist Mono 大号
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderStrong, width: 0.8),
          ),
          child: Text(
            _formatCode(_code!),
            textAlign: TextAlign.center,
            style: AppTheme.mono(
              size: 32,
              weight: FontWeight.w700,
              color: AppTheme.fg,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // 倒计时
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.timer, size: 13, color: AppTheme.priorityP1),
            const SizedBox(width: 6),
            Text(
              '有效期剩余 ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: AppTheme.mono(
                size: 11,
                weight: FontWeight.w600,
                color: AppTheme.priorityP1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_code == null && !_isGenerating)
          Expanded(
            child: OutlinedButton(
              onPressed: _generateCode,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.fg,
                side: const BorderSide(color: AppTheme.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '重新生成',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.fg,
              foregroundColor: AppTheme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              '关闭',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 2)} ${code.substring(2, 4)} ${code.substring(4, 6)}';
  }
}
