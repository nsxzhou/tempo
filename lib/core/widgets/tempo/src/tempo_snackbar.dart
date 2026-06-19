// TempoSnackbar — 顶部黑色 Toast（对应 prototype Snackbar.tsx）
// bg #0A0A0A 白字 + 可选撤销链接 + 3s 自动消失

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../theme/app_theme.dart';

class TempoSnackbar {
  TempoSnackbar._();

  static const _defaultDuration = Duration(milliseconds: 3000);
  static Timer? _autoDismissTimer;

  /// 显示一条顶部黑色 Toast。
  /// [message] 正文;[undoLabel]/[onUndo] 可选撤销链接。
  static void show(
    BuildContext context, {
    required String message,
    String? undoLabel,
    Future<void> Function()? onUndo,
    Duration duration = _defaultDuration,
  }) {
    final container = ProviderScope.containerOf(context, listen: false);
    final messengerKey = container.read(scaffoldMessengerKeyProvider);
    final rootState = messengerKey.currentState;
    final messenger = rootState ?? ScaffoldMessenger.of(context);

    final media = MediaQuery.of(context);
    // SnackBar 默认贴底；用大 bottom margin 将其推到状态栏下方
    const estimatedBarHeight = 56.0;
    final topMargin = media.size.height -
        media.padding.top -
        estimatedBarHeight -
        12;

    _autoDismissTimer?.cancel();
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
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
        dismissDirection: DismissDirection.up,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: EdgeInsets.fromLTRB(16, 0, 16, topMargin),
        duration: duration,
        action: (undoLabel != null && onUndo != null)
            ? SnackBarAction(
                label: undoLabel,
                textColor: AppTheme.bg,
                onPressed: () {
                  _autoDismissTimer?.cancel();
                  messenger.hideCurrentSnackBar();
                  onUndo();
                },
              )
            : null,
      ),
    );

    // GoRouter ShellRoute 下内置 duration 计时不可靠，手动 Timer 兜底
    _autoDismissTimer = Timer(duration, messenger.hideCurrentSnackBar);
  }
}
