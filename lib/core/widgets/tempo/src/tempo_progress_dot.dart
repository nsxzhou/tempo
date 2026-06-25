// TempoProgressDot — 时间轴圆点(对应 prototype PlanView 流程排期)
// 12px 圆 + 2px 边,选中态黑色填充 + 双圈光晕

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tempo_theme_extension.dart';

class TempoProgressDot extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  final double size;

  const TempoProgressDot({
    super.key,
    required this.active,
    this.onTap,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active ? t.fg : t.bg,
              border: Border.all(
                color: active ? t.fg : t.borderEmphasis,
                width: 2,
              ),
              shape: BoxShape.circle,
              boxShadow: active ? AppTheme.shadowSelectedDot : null,
            ),
          ),
        ),
      ),
    );
  }
}
