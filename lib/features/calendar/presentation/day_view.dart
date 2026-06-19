// DayView — 日视图(对应 prototype CalendarView.tsx 日视图)
// 左侧 chevron + 大字号日期 + 右侧 chevron

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../tasks/domain/task.dart';

class DayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final ValueChanged<DateTime> onChange;

  const DayView({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _sameDay(selectedDate, now);
    final isFuture = selectedDate.isAfter(
        DateTime(now.year, now.month, now.day));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
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
                  style: AppTheme.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppTheme.fgSubtle,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('M 月 d 日').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday ? '今天' : '周${_cnWeekday(selectedDate.weekday)}',
                  style: AppTheme.mono(
                    size: 11,
                    color: AppTheme.fgMuted,
                  ),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: const BorderSide(color: AppTheme.borderStrong, width: 0.8),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppTheme.fgMuted),
          ),
        ),
      ),
    );
  }
}
