// TempoSnackbar — 黑色 Toast(对应 prototype Snackbar.tsx)
// bg #0A0A0A 白字 + 可选撤销链接 + 4.5s 自动消失 + spring 入场

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoSnackbar {
  TempoSnackbar._();

  /// 显示一条黑色 Toast。
  /// [message] 正文;[undoLabel]/[onUndo] 可选撤销链接。
  static void show(
    BuildContext context, {
    required String message,
    String? undoLabel,
    VoidCallback? onUndo,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.35,
              color: AppTheme.bg,
            ),
          ),
          backgroundColor: AppTheme.fg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          duration: duration,
          action: (undoLabel != null && onUndo != null)
              ? SnackBarAction(
                  label: undoLabel,
                  textColor: AppTheme.bg,
                  onPressed: onUndo,
                )
              : null,
        ),
      );
  }
}
