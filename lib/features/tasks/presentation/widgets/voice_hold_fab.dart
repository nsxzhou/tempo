import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';

/// Tasks 页浮动操作：mic 长按说话 + plus 快速创建。
class VoiceHoldFabColumn extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onHoldStart;
  final ValueChanged<double> onHoldMove;
  final void Function(bool cancelled) onHoldEnd;

  const VoiceHoldFabColumn({
    super.key,
    required this.onAdd,
    required this.onHoldStart,
    required this.onHoldMove,
    required this.onHoldEnd,
  });

  static const double slideCancelThreshold = 80;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => onHoldStart(),
          onPointerMove: (event) => onHoldMove(event.localPosition.dy),
          onPointerUp: (event) {
            final cancelled = event.localPosition.dy < -slideCancelThreshold;
            onHoldEnd(cancelled);
          },
          onPointerCancel: (_) => onHoldEnd(true),
          child: Material(
            color: t.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(color: t.borderStrong, width: 0.8),
            ),
            elevation: 0,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(LucideIcons.mic, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: t.fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: t.fg, width: 0.8),
          ),
          elevation: 0,
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(LucideIcons.plus, size: 22, color: t.bg),
            ),
          ),
        ),
      ],
    );
  }
}
