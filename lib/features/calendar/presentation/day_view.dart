// DayView — 日视图(对应 prototype CalendarView.tsx 日视图)
// 左侧 chevron + 大字号日期 + 右侧 chevron

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/tempo/tempo.dart';

class DayView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChange;

  const DayView({
    super.key,
    required this.selectedDate,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);
    final isFuture = selectedDate.isAfter(
      DateTime(now.year, now.month, now.day),
    );

    return TempoGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左 chevron
          _NavBtn(
            icon: LucideIcons.chevron_left,
            enabled: !isToday,
            onTap: () =>
                onChange(selectedDate.subtract(const Duration(days: 1))),
          ),
          // 大字日期
          Expanded(
            child: Column(
              children: [
                Text(
                  'SELECTED DAY',
                  style: tokens.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: tokens.fgSubtle,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('M 月 d 日').format(selectedDate),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: tokens.fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday ? '今天' : '周${_cnWeekday(selectedDate.weekday)}',
                  style: tokens.mono(size: 11, color: tokens.fgMuted),
                ),
              ],
            ),
          ),
          // 右 chevron
          _NavBtn(
            icon: LucideIcons.chevron_right,
            enabled: isFuture,
            onTap: () => onChange(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  String _cnWeekday(int wd) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[(wd - 1) % 7];
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: TempoGlassSurface(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: tokens.fgMuted),
            ),
          ),
        ),
      ),
    );
  }
}
