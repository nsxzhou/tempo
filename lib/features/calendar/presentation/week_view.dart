// WeekView — 周视图(对应 prototype CalendarView.tsx 周视图)
// 7 列日期 chip,选中态黑底白字 + 圆点

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../tasks/domain/task.dart';

class WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> taskIndex;
  final ValueChanged<DateTime> onSelectDate;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.taskIndex,
    required this.onSelectDate,
  });

  /// 本周一的日期
  DateTime get _monday {
    final wd = selectedDate.weekday; // 1=Mon..7=Sun
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day - (wd - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final days = List.generate(7, (i) => _monday.add(Duration(days: i)));
    final now = DateTime.now();

    return TempoGlassSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: List.generate(7, (i) {
          final day = days[i];
          final dayKey = DateTime(day.year, day.month, day.day);
          final isSel = isSameDay(day, selectedDate);
          final isToday = isSameDay(day, now);
          final hasTask = taskIndex[dayKey]?.isNotEmpty ?? false;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: GestureDetector(
                onTap: () => onSelectDate(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? tokens.fg : tokens.bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSel
                          ? tokens.fg
                          : (isToday
                                ? tokens.fg.withValues(alpha: 0.3)
                                : tokens.borderStrong),
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
                        style: tokens.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          color: isSel ? tokens.bg : tokens.fgMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: tokens.mono(
                          size: 16,
                          weight: FontWeight.w700,
                          color: isSel ? tokens.bg : tokens.fgSecondary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSel
                              ? tokens.bg
                              : (hasTask ? tokens.fgFaint : Colors.transparent),
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
