// MonthView — 月视图(对应 prototype CalendarView.tsx 月视图)
// 7x6 网格 + 3px 优先级点 + 选中态黑底圆

import 'package:flutter/material.dart';
import 'package:tempo/core/utils/date_utils.dart';

import '../../../../core/theme/app_theme.dart';
import '../../tasks/domain/task.dart';

class MonthView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelectDate;

  const MonthView({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.onSelectDate,
  });

  List<Color> _dotsForDay(DateTime day) {
    final dayTasks = tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      return isDueOnDate(t.dueDate!, day);
    }).toList();

    // 取前 3 个不同优先级
    final seen = <int>{};
    final dots = <Color>[];
    for (final t in dayTasks) {
      if (seen.add(t.priority.value)) {
        dots.add(AppTheme.priorityColor(t.priority.value));
        if (dots.length >= 3) break;
      }
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    // 一周从周一开始 → weekday: 1=Mon..7=Sun
    final leadingEmpty = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // 构造 6x7 = 42 格
    final cells = <_MonthCell>[];
    // 前导
    for (int i = 0; i < leadingEmpty; i++) {
      final d = firstDay.subtract(Duration(days: leadingEmpty - i));
      cells.add(_MonthCell(date: d, isOtherMonth: true));
    }
    // 当月
    for (int i = 1; i <= daysInMonth; i++) {
      cells.add(_MonthCell(date: DateTime(selectedDate.year, selectedDate.month, i)));
    }
    // 尾部填充到 42
    while (cells.length < 42) {
      final last = cells.last.date.add(const Duration(days: 1));
      cells.add(_MonthCell(date: last, isOtherMonth: true));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // 星期头
          Row(
            children: const ['一', '二', '三', '四', '五', '六', '日']
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: AppTheme.mono(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppTheme.fgSubtle,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // 6 行
          for (int row = 0; row < 6; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final cell = cells[row * 7 + col];
                  return Expanded(
                    child: _DayCell(
                      cell: cell,
                      dots: _dotsForDay(cell.date),
                      isToday: isSameDay(cell.date, now),
                      isSelected: isSameDay(cell.date, selectedDate) && !cell.isOtherMonth,
                      onTap: cell.isOtherMonth
                          ? null
                          : () => onSelectDate(cell.date),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

}

class _MonthCell {
  final DateTime date;
  final bool isOtherMonth;
  _MonthCell({required this.date, this.isOtherMonth = false});
}

class _DayCell extends StatelessWidget {
  final _MonthCell cell;
  final List<Color> dots;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;
  const _DayCell({
    required this.cell,
    required this.dots,
    required this.isToday,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dim = cell.isOtherMonth;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.fg : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.fg, width: 1)
                    : null,
              ),
              child: Text(
                '${cell.date.day}',
                style: AppTheme.mono(
                  size: 12,
                  weight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.bg
                      : (dim
                          ? AppTheme.fgFaint
                          : (isToday ? AppTheme.fg : AppTheme.fgSecondary)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  if (i >= dots.length) return const SizedBox(width: 3);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.bg : dots[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
