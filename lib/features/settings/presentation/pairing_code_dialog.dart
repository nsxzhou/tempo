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
import '../../../core/theme/tempo_theme_extension.dart';
import '../data/siyuan_pairing_service.dart';

class PairingCodeDialog extends ConsumerStatefulWidget {
  const PairingCodeDialog({super.key, this.existingCode});

  final PairingCode? existingCode;

  static Future<void> show(BuildContext context, {PairingCode? existingCode}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => PairingCodeDialog(existingCode: existingCode),
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
    final existing = widget.existingCode;
    if (existing != null && existing.isValid) {
      _applyCode(existing.code, existing.expiresAt);
    } else {
      _generateCode();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _applyCode(String code, DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      setState(() {
        _code = null;
        _isGenerating = false;
      });
      return;
    }

    _timer?.cancel();
    _remainingSeconds = remaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() => _code = null);
        }
      } else if (mounted) {
        setState(() => _remainingSeconds--);
      }
    });

    setState(() {
      _code = code;
      _isGenerating = false;
      _errorMessage = null;
    });
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

      _applyCode(code, DateTime.now().add(AppConstants.pairingCodeExpiry));
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
    final t = context.tokens;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: t.borderStrong, width: 0.8),
          boxShadow: AppTheme.shadowSm,
        ),
        child: _buildContent(t),
      ),
    );
  }

  Widget _buildContent(TempoTokens t) {
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.fg,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(LucideIcons.x, size: 16, color: t.fgMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildBody(t),
        const SizedBox(height: 20),
        _buildActions(t),
      ],
    );
  }

  Widget _buildBody(TempoTokens t) {
    if (_isGenerating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.fg),
          ),
          const SizedBox(height: 16),
          Text('正在生成配对码...', style: t.mono(size: 11, color: t.fgMuted)),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.circle_alert,
            color: AppTheme.priorityP0,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.priorityP0,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    if (_code == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer_off, size: 32, color: t.fgMuted),
          const SizedBox(height: 12),
          Text(
            '配对码已过期',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.fgSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text('请重新生成', style: t.mono(size: 10, color: t.fgMuted)),
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
          style: TextStyle(fontSize: 11, color: t.fgMuted, height: 1.5),
        ),
        const SizedBox(height: 16),
        // 配对码 Geist Mono 大号
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: t.bgSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: t.borderStrong, width: 0.8),
          ),
          child: Text(
            _formatCode(_code!),
            textAlign: TextAlign.center,
            style: t.mono(
              size: 32,
              weight: FontWeight.w700,
              color: t.fg,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // 倒计时
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.timer, size: 13, color: AppTheme.priorityP1),
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

  Widget _buildActions(TempoTokens t) {
    return Row(
      children: [
        if (_code == null && !_isGenerating)
          Expanded(
            child: OutlinedButton(
              onPressed: _generateCode,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.fg,
                side: BorderSide(color: t.borderStrong),
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
              backgroundColor: t.fg,
              foregroundColor: t.bg,
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
