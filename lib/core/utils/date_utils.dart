/// 日期比较工具（日历 / 本周过滤 / 重复任务共用）
library;

/// 归一化为本地时区年月日（时分秒归零）。
DateTime calendarDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// 判断 [a] 与 [b] 是否为同一天（本地时区年月日）。
bool isSameDay(DateTime a, DateTime b) {
  return calendarDay(a) == calendarDay(b);
}

/// 判断 [dueDate] 是否落在 [date] 当天。
bool isDueOnDate(DateTime dueDate, DateTime date) {
  return isSameDay(dueDate, date);
}

/// 判断 [dueDate] 是否在 [todayStart, todayStart + 7天) 区间内。
bool isDueInWeekRange(DateTime dueDate, DateTime now) {
  final todayStart = calendarDay(now);
  final weekEnd = todayStart.add(const Duration(days: 7));
  return !dueDate.isBefore(todayStart) && dueDate.isBefore(weekEnd);
}

/// 全天任务在当天结束前不算过期。
bool isTaskOverdue({
  required DateTime dueDate,
  required bool isAllDay,
  required bool isCompleted,
  DateTime? now,
}) {
  if (isCompleted) return false;
  final current = now ?? DateTime.now();
  if (isAllDay) {
    final endOfDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );
    return current.isAfter(endOfDay);
  }
  return dueDate.isBefore(current);
}

/// 详情页截止日期展示。
String formatTaskDueDetail({
  required DateTime dueDate,
  required bool isAllDay,
}) {
  if (isAllDay) {
    return '${dueDate.month}月${dueDate.day}日';
  }
  return '${dueDate.month}月${dueDate.day}日 ${_hm(dueDate)}';
}

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 任务详情 URL `?date=` 查询参数（`yyyy-MM-dd` 日历日）。
String formatOccurrenceDateQuery(DateTime day) {
  final d = calendarDay(day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dayStr = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dayStr';
}

/// 解析 [formatOccurrenceDateQuery] 格式；非法则返回 null。
DateTime? parseOccurrenceDateQuery(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}
