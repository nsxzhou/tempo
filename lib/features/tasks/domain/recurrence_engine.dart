import 'package:rrule/rrule.dart';

import '../../../core/utils/date_utils.dart' as date_utils;
import 'recurrence_models.dart';
import 'task.dart';

/// 重复任务展开、状态判定与 streak 计算
class RecurrenceEngine {
  const RecurrenceEngine();

  static DateTime calendarDay(DateTime dt) => date_utils.calendarDay(dt);

  /// 在 [from, to] 窗口内展开 occurrence（含例外处理）
  List<TaskOccurrence> expandOccurrences(
    Task task, {
    required DateTime from,
    required DateTime to,
    List<RecurrenceException> exceptions = const [],
    List<TaskCompletion> completions = const [],
    DateTime? now,
  }) {
    if (!task.isRecurring || task.dueDate == null) return const [];

    final rrule = _buildRule(task);
    if (rrule == null) return const [];

    final fromDay = calendarDay(from);
    final toDay = calendarDay(to);
    final today = calendarDay(now ?? DateTime.now());
    final exceptionMap = {
      for (final e in exceptions) calendarDay(e.exceptionDate): e,
    };
    final completionDays = completions
        .map((c) => calendarDay(c.occurrenceDate))
        .toSet();

    final anchor = task.dueDate!;
    // rrule 要求 UTC，但保留本地日期/时刻数值
    final start = anchor.copyWith(isUtc: true);

    final iter = rrule.getInstances(start: start);
    final results = <TaskOccurrence>[];

    for (final instance in iter) {
      final local = instance.copyWith(isUtc: false);
      final day = calendarDay(local);
      if (day.isBefore(fromDay)) continue;
      if (day.isAfter(toDay)) break;

      if (task.recurrenceEnd != null &&
          day.isAfter(calendarDay(task.recurrenceEnd!))) {
        break;
      }

      final ex = exceptionMap[day];
      if (ex?.isCancelled == true) continue;

      final effectiveDue = _effectiveDue(task, day, ex);
      final title = ex?.overrideTitle ?? task.title;
      final state = _stateFor(day, completionDays, today);

      results.add(
        TaskOccurrence(
          seriesTaskId: task.id,
          occurrenceDate: day,
          effectiveDue: effectiveDue,
          title: title,
          state: state,
        ),
      );

      if (task.recurrenceCount != null &&
          results.length >= task.recurrenceCount!) {
        break;
      }
    }

    return results;
  }

  /// 下一次 occurrence（含今天未完成）
  TaskOccurrence? nextOccurrence(
    Task task, {
    DateTime? after,
    List<RecurrenceException> exceptions = const [],
    List<TaskCompletion> completions = const [],
    DateTime? now,
  }) {
    if (!task.isRecurring) return null;
    final pivot = after ?? now ?? DateTime.now();
    final from = calendarDay(pivot);
    final to = from.add(const Duration(days: 366));
    final all = expandOccurrences(
      task,
      from: from,
      to: to,
      exceptions: exceptions,
      completions: completions,
      now: now,
    );
    for (final occ in all) {
      if (occ.state == OccurrenceState.pending) return occ;
    }
    return null;
  }

  OccurrenceState stateForDate(
    Task task,
    DateTime occurrenceDate, {
    List<TaskCompletion> completions = const [],
    DateTime? now,
  }) {
    final day = calendarDay(occurrenceDate);
    final today = calendarDay(now ?? DateTime.now());
    final completionDays = completions
        .map((c) => calendarDay(c.occurrenceDate))
        .toSet();
    return _stateFor(day, completionDays, today);
  }

  StreakInfo computeStreak(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
    DateTime? now,
    int lookbackDays = 365,
  }) {
    if (!task.isRecurring) {
      return const StreakInfo(
        current: 0,
        longest: 0,
        completedCount: 0,
        scheduledCount: 0,
      );
    }

    final today = calendarDay(now ?? DateTime.now());
    final from = today.subtract(Duration(days: lookbackDays));
    final occurrences = expandOccurrences(
      task,
      from: from,
      to: today,
      exceptions: exceptions,
      completions: completions,
      now: now,
    );

    final scheduled = occurrences
        .where((o) => !o.occurrenceDate.isAfter(today))
        .toList();
    final completedCount =
        scheduled.where((o) => o.state == OccurrenceState.completed).length;

    var current = 0;
    var longest = 0;
    var run = 0;
    for (final occ in scheduled) {
      if (occ.state == OccurrenceState.completed) {
        run++;
        if (run > longest) longest = run;
      } else if (!occ.occurrenceDate.isAfter(today)) {
        run = 0;
      }
    }

    for (var i = scheduled.length - 1; i >= 0; i--) {
      final occ = scheduled[i];
      if (occ.occurrenceDate.isAfter(today)) continue;
      if (occ.state == OccurrenceState.completed) {
        current++;
      } else {
        break;
      }
    }

    return StreakInfo(
      current: current,
      longest: longest,
      completedCount: completedCount,
      scheduledCount: scheduled.length,
    );
  }

  RecurrenceRule? _buildRule(Task task) {
    final ruleStr = task.recurrenceRule;
    if (ruleStr == null || ruleStr.isEmpty) return null;

    try {
      final parsed = RecurrenceRule.fromString('RRULE:$ruleStr');
      final until = task.recurrenceEnd;
      final count = task.recurrenceCount;

      if (until != null) {
        final u = until.toUtc();
        return RecurrenceRule(
          frequency: parsed.frequency,
          interval: parsed.interval,
          byWeekDays: parsed.byWeekDays,
          byMonthDays: parsed.byMonthDays,
          byMonths: parsed.byMonths,
          until: u,
          weekStart: parsed.weekStart,
          bySetPositions: parsed.bySetPositions,
          byHours: parsed.byHours,
          byMinutes: parsed.byMinutes,
          bySeconds: parsed.bySeconds,
        );
      }
      if (count != null) {
        return RecurrenceRule(
          frequency: parsed.frequency,
          interval: parsed.interval,
          byWeekDays: parsed.byWeekDays,
          byMonthDays: parsed.byMonthDays,
          byMonths: parsed.byMonths,
          count: count,
          weekStart: parsed.weekStart,
          bySetPositions: parsed.bySetPositions,
          byHours: parsed.byHours,
          byMinutes: parsed.byMinutes,
          bySeconds: parsed.bySeconds,
        );
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  DateTime? _effectiveDue(
    Task task,
    DateTime day,
    RecurrenceException? ex,
  ) {
    if (ex?.overrideDue != null) return ex!.overrideDue;
    final anchor = task.dueDate;
    if (anchor == null) return null;
    if (task.isAllDay) return day;
    return DateTime(
      day.year,
      day.month,
      day.day,
      anchor.hour,
      anchor.minute,
      anchor.second,
    );
  }

  OccurrenceState _stateFor(
    DateTime day,
    Set<DateTime> completionDays,
    DateTime today,
  ) {
    if (completionDays.contains(day)) return OccurrenceState.completed;
    if (day.isBefore(today)) return OccurrenceState.missed;
    return OccurrenceState.pending;
  }
}
