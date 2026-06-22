// TempoSheet — 统一底部抽屉动效
// 上滑 easeOutCubic 350ms · 遮罩淡入 300ms · 关闭 easeInCubic

import 'package:flutter/material.dart';

import '../debug/agent_debug_log.dart';
import '../theme/app_theme.dart';

/// Tempo 统一 bottom sheet 入口
class TempoSheet {
  TempoSheet._();

  /// 弹出底部 sheet，返回 Navigator.pop 的值
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: AppTheme.durationMedium,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final bottomInset = isScrollControlled
            ? MediaQuery.viewInsetsOf(dialogContext).bottom
            : 0.0;

        // #region agent log
        agentDebugLog(
          location: 'tempo_sheet.dart:pageBuilder',
          message: 'TempoSheet keyboard inset',
          hypothesisId: 'H1',
          data: {
            'bottomInset': bottomInset,
            'isScrollControlled': isScrollControlled,
            'viewPaddingBottom':
                MediaQuery.viewPaddingOf(dialogContext).bottom,
          },
        );
        // #endregion

        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Material(
                color: Colors.transparent,
                child: enableDrag
                    ? _DraggableSheetContent(child: builder(dialogContext))
                    : builder(dialogContext),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final sheetCurve = CurvedAnimation(
          parent: animation,
          curve: AppTheme.curveOrganic,
          reverseCurve: Curves.easeInCubic,
        );
        final barrierCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.85, curve: Curves.easeOut),
          reverseCurve: Curves.easeIn,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: isDismissible ? () => Navigator.of(context).pop() : null,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(
                color: Color.lerp(
                  Colors.transparent,
                  AppTheme.sheetBarrierColor,
                  barrierCurve.value,
                )!,
              ),
            ),
            Transform.translate(
              offset: Offset(0, (1 - sheetCurve.value) * 48),
              child: Opacity(
                opacity: sheetCurve.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraggableSheetContent extends StatelessWidget {
  final Widget child;

  const _DraggableSheetContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 12) {
          Navigator.of(context).maybePop();
        }
      },
      child: child,
    );
  }
}
