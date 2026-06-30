// DayView — 日视图：居中展示选中日期（导航由 CalendarPage 页眉驱动）

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/tempo/tempo.dart';

class DayView extends StatelessWidget {
  final DateTime selectedDate;

  const DayView({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);

    return TempoGlassSurface(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    );
  }

  String _cnWeekday(int wd) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[(wd - 1) % 7];
  }
}
