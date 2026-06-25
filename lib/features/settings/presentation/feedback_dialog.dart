// ============================================================
// FeedbackDialog — 反馈输入弹窗(对齐 Stripe 派设计系统)
// 自定义 Dialog + 主题输入框 + 设备信息条 + TempoSnackbar
// 逻辑保留:submit / collectDeviceInfo / 错误重试
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/widgets/tempo/tempo.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (_) => const FeedbackDialog());
  }

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '提交反馈',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.fg,
                    letterSpacing: -0.2,
                  ),
                ),
                GestureDetector(
                  onTap: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Icon(LucideIcons.x, size: 16, color: t.fgMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 反馈输入框
            TextField(
              controller: _controller,
              maxLines: 5,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: t.fg, height: 1.5),
              decoration: InputDecoration(
                hintText: '请描述你遇到的问题或建议...',
                hintStyle: TextStyle(fontSize: 12, color: t.fgSubtle),
                filled: true,
                fillColor: t.bgSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: t.borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: t.borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: t.fg, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            // 设备信息提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 13, color: t.fgMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '将自动附带设备信息(平台/版本)',
                      style: TextStyle(fontSize: 10, color: t.fgMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // 按钮行
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.fgMuted,
                      side: BorderSide(color: t.borderStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: t.fg,
                      foregroundColor: t.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: t.bg,
                            ),
                          )
                        : const Text(
                            '提交',
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
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      TempoSnackbar.show(context, message: '请输入反馈内容');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(feedbackServiceProvider);
      await service.submit(content, deviceInfo: _collectDeviceInfo());

      if (!mounted) return;
      Navigator.pop(context);
      TempoSnackbar.show(context, message: '反馈已提交,感谢!');
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(
        context,
        message: '提交失败:$error',
        undoLabel: '重试',
        onUndo: _submit,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Map<String, dynamic> _collectDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'app_version': AppConstants.appVersion,
      'locale': Platform.localeName,
    };
  }
}
