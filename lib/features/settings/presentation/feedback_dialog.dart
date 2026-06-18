// ============================================================
// FeedbackDialog — 反馈输入弹窗（文字 + 自动附带设备信息）
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// 反馈输入弹窗。
///
/// 用户输入文字反馈，自动附带设备信息提交到 Supabase。
class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  /// 显示反馈弹窗。
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const FeedbackDialog(),
    );
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
    return AlertDialog(
      title: const Text('提交反馈'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '请描述你遇到的问题或建议...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // 设备信息提示
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '将自动附带设备信息（平台/版本）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('提交'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入反馈内容')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(feedbackServiceProvider);
      await service.submit(content, deviceInfo: _collectDeviceInfo());

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反馈已提交，感谢！')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交失败：$error'),
          action: SnackBarAction(label: '重试', onPressed: _submit),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 收集设备信息。
  Map<String, dynamic> _collectDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'app_version': AppConstants.appVersion,
      'locale': Platform.localeName,
    };
  }
}
