// WeekView — 周视图(对应 prototype CalendarView.tsx 周视图)
// 7 列日期 chip,选中态黑底白字 + 圆点

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../tasks/domain/task.dart';

class WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelectDate;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.onSelectDate,
  });

  /// 本周一的日期
  DateTime get _monday {
    final wd = selectedDate.weekday; // 1=Mon..7=Sun
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day - (wd - 1));
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _monday.add(Duration(days: i)));
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: List.generate(7, (i) {
          final day = days[i];
          final isSel = isSameDay(day, selectedDate);
          final isToday = isSameDay(day, now);
          final hasTask = tasks.any((t) =>
              t.dueDate != null && isSameDay(t.dueDate!, day));
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: GestureDetector(
                onTap: () => onSelectDate(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.fg : AppTheme.bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSel
                          ? AppTheme.fg
                          : (isToday
                              ? AppTheme.fg.withValues(alpha: 0.3)
                              : AppTheme.borderStrong),
                      width: 0.8,
                    ),
                    boxShadow: isSel
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weekdayLabel(day.weekday),
                        style: AppTheme.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          color: isSel ? AppTheme.bg : AppTheme.fgMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: AppTheme.mono(
                          size: 16,
                          weight: FontWeight.w700,
                          color: isSel ? AppTheme.bg : AppTheme.fgSecondary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.bg
                              : (hasTask ? AppTheme.fgFaint : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _weekdayLabel(int wd) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[(wd - 1) % 7];
  }

}
