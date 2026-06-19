// TempoToggle — 自定义 Toggle(对应 prototype 设置页 34×20 圆胶囊)

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  const TempoToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.width = 34,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = height - 4;
    return Semantics(
      label: value ? '已开启' : '已关闭',
      button: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: value ? AppTheme.fg : AppTheme.bgMuted,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: value ? AppTheme.fg : AppTheme.borderStrong,
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                top: 2,
                left: value ? width - dotSize - 2 : 2,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.shadowSm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
