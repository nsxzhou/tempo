// TempoPropertyRow — 详情页属性行(对应 prototype DetailView 4 行 metadata)
// lucide 图标 + 11px UPPERCASE 标签(宽 48) + 14px Geist 文本,行高 ~50px

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class TempoPropertyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TempoPropertyRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.fgMuted),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(
                label.toUpperCase(),
                style: AppTheme.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  color: AppTheme.fgMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: value),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
