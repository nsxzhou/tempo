// TempoCheckbox — 圆形 Checkbox
// 对应 prototype 任务列表 18px 圆 Checkbox
// 选中 bg 黑 + Check icon,带 0.85 → 1.0 弹动

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../theme/app_theme.dart';

class TempoCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final bool enabled;

  const TempoCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 18,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value ? '已完成' : '未完成',
      button: onChanged != null,
      child: GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: value ? AppTheme.fg : AppTheme.bg,
            border: Border.all(
              color: value ? AppTheme.fg : AppTheme.borderEmphasis,
              width: 1.2,
            ),
            shape: BoxShape.circle,
          ),
          child: AnimatedScale(
            scale: value ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: value
            ? Icon(
                LucideIcons.check,
                size: size * 0.55,
                color: AppTheme.bg,
              )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
