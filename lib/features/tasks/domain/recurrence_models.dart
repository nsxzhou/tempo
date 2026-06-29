/// 重复任务相关领域模型
library;

import 'task.dart';

/// occurrence 状态
enum OccurrenceState { pending, completed, missed }

/// 单次 occurrence
class TaskOccurrence {
  const TaskOccurrence({
    required this.seriesTaskId,
    required this.occurrenceDate,
    required this.effectiveDue,
    required this.title,
    this.state = OccurrenceState.pending,
  });

  final String seriesTaskId;
  final DateTime occurrenceDate;
  final DateTime? effectiveDue;
  final String title;
  final OccurrenceState state;

  DateTime get calendarDay => DateTime(
    occurrenceDate.year,
    occurrenceDate.month,
    occurrenceDate.day,
  );

  TaskOccurrence copyWith({
    DateTime? occurrenceDate,
    DateTime? effectiveDue,
    String? title,
    OccurrenceState? state,
  }) {
    return TaskOccurrence(
      seriesTaskId: seriesTaskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      effectiveDue: effectiveDue ?? this.effectiveDue,
      title: title ?? this.title,
      state: state ?? this.state,
    );
  }
}

/// 重复例外
class RecurrenceException {
  const RecurrenceException({
    required this.taskId,
    required this.exceptionDate,
    this.overrideDue,
    this.overrideTitle,
    this.isCancelled = false,
    this.syncPending = false,
  });

  final String taskId;
  final DateTime exceptionDate;
  final DateTime? overrideDue;
  final String? overrideTitle;
  final bool isCancelled;
  final bool syncPending;

  DateTime get calendarDay => DateTime(
    exceptionDate.year,
    exceptionDate.month,
    exceptionDate.day,
  );
}

/// 打卡完成记录
class TaskCompletion {
  const TaskCompletion({
    required this.taskId,
    required this.occurrenceDate,
    required this.completedAt,
    this.syncPending = false,
  });

  final String taskId;
  final DateTime occurrenceDate;
  final DateTime completedAt;
  final bool syncPending;

  DateTime get calendarDay => DateTime(
    occurrenceDate.year,
    occurrenceDate.month,
    occurrenceDate.day,
  );
}

/// Streak 统计
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.longest,
    required this.completedCount,
    required this.scheduledCount,
  });

  final int current;
  final int longest;
  final int completedCount;
  final int scheduledCount;

  double get completionRate =>
      scheduledCount == 0 ? 0 : completedCount / scheduledCount;
}

/// 列表/日历展示用：将 series task 与 occurrence 合并
class TaskOccurrenceView {
  const TaskOccurrenceView({
    required this.seriesTask,
    required this.occurrence,
  });

  final Task seriesTask;
  final TaskOccurrence occurrence;

  /// 用于 UI 绑定的 Task（id 仍为 series id，附带 occurrence 上下文）
  Task get displayTask {
    final occ = occurrence;
    final completed = occ.state == OccurrenceState.completed;
    return seriesTask.copyWith(
      dueDate: occ.effectiveDue,
      title: occ.title,
      isCompleted: completed,
      completedAt: completed ? occ.effectiveDue : null,
    );
  }

  bool get isRecurring => seriesTask.isRecurring;
}

/// 重复规则 UI 配置（创建/编辑表单用）
class RecurrenceConfig {
  const RecurrenceConfig({
    required this.interval,
    required this.unit,
    this.weekdays = const {},
    this.endDate,
    this.occurrenceCount,
  });

  final int interval;
  final RecurrenceUnit unit;
  final Set<int> weekdays;
  final DateTime? endDate;
  final int? occurrenceCount;

  bool get hasRecurrence => interval > 0;

  static const none = RecurrenceConfig(interval: 0, unit: RecurrenceUnit.day);

  String toRRule() {
    if (!hasRecurrence) return '';
    final parts = <String>['INTERVAL=$interval'];
    switch (unit) {
      case RecurrenceUnit.day:
        parts.insert(0, 'FREQ=DAILY');
      case RecurrenceUnit.week:
        parts.insert(0, 'FREQ=WEEKLY');
        if (weekdays.isNotEmpty) {
          parts.add('BYDAY=${weekdays.map(_weekdayCode).join(',')}');
        }
      case RecurrenceUnit.month:
        parts.insert(0, 'FREQ=MONTHLY');
    }
    return parts.join(';');
  }

  static RecurrenceConfig? fromRRule(String? rule) {
    if (rule == null || rule.trim().isEmpty) return null;
    final parts = <String, String>{};
    for (final segment in rule.split(';')) {
      final kv = segment.split('=');
      if (kv.length == 2) parts[kv[0].trim()] = kv[1].trim();
    }
    final freq = parts['FREQ'];
    if (freq == null) return null;
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final unit = switch (freq) {
      'DAILY' => RecurrenceUnit.day,
      'WEEKLY' => RecurrenceUnit.week,
      'MONTHLY' => RecurrenceUnit.month,
      _ => RecurrenceUnit.day,
    };
    final weekdays = <int>{};
    final byDay = parts['BYDAY'];
    if (byDay != null) {
      for (final code in byDay.split(',')) {
        final day = _codeToWeekday(code.trim());
        if (day != null) weekdays.add(day);
      }
    }
    return RecurrenceConfig(interval: interval, unit: unit, weekdays: weekdays);
  }
}

enum RecurrenceUnit { day, week, month }

String _weekdayCode(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'MO',
    DateTime.tuesday => 'TU',
    DateTime.wednesday => 'WE',
    DateTime.thursday => 'TH',
    DateTime.friday => 'FR',
    DateTime.saturday => 'SA',
    DateTime.sunday => 'SU',
    _ => 'MO',
  };
}

int? _codeToWeekday(String code) {
  return switch (code.toUpperCase()) {
    'MO' => DateTime.monday,
    'TU' => DateTime.tuesday,
    'WE' => DateTime.wednesday,
    'TH' => DateTime.thursday,
    'FR' => DateTime.friday,
    'SA' => DateTime.saturday,
    'SU' => DateTime.sunday,
    _ => null,
  };
}

/// 人类可读的重复规则摘要
String recurrenceSummary(Task task) {
  if (!task.isRecurring) return '';
  final config = RecurrenceConfig.fromRRule(task.recurrenceRule);
  if (config == null) return task.recurrenceRule!;
  final unitLabel = switch (config.unit) {
    RecurrenceUnit.day => '天',
    RecurrenceUnit.week => '周',
    RecurrenceUnit.month => '月',
  };
  final buffer = StringBuffer('每');
  if (config.interval > 1) buffer.write('${config.interval}');
  buffer.write(unitLabel);
  if (config.unit == RecurrenceUnit.week && config.weekdays.isNotEmpty) {
    const names = {
      DateTime.monday: '一',
      DateTime.tuesday: '二',
      DateTime.wednesday: '三',
      DateTime.thursday: '四',
      DateTime.friday: '五',
      DateTime.saturday: '六',
      DateTime.sunday: '日',
    };
    final days = config.weekdays.map((d) => names[d] ?? '').join('');
    buffer.write('（周$days）');
  }
  if (task.recurrenceEnd != null) {
    buffer.write('，至 ${task.recurrenceEnd!.month}/${task.recurrenceEnd!.day}');
  } else if (task.recurrenceCount != null) {
    buffer.write('，共 ${task.recurrenceCount} 次');
  }
  return buffer.toString();
}
