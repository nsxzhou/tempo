/// 日期比较工具（日历 / 本周过滤共用）

/// 判断 [a] 与 [b] 是否为同一天（本地时区年月日）。
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// 判断 [dueDate] 是否落在 [date] 当天。
bool isDueOnDate(DateTime dueDate, DateTime date) {
  return isSameDay(dueDate, date);
}

/// 判断 [dueDate] 是否在 [todayStart, todayStart + 7天) 区间内。
bool isDueInWeekRange(DateTime dueDate, DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekEnd = todayStart.add(const Duration(days: 7));
  return !dueDate.isBefore(todayStart) && dueDate.isBefore(weekEnd);
}
