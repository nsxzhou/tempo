import '../../tasks/domain/task.dart';

/// 单日完成量
class DailyCompletion {
  final DateTime date;
  final int count;

  const DailyCompletion({required this.date, required this.count});
}

/// 优先级扇区
class PrioritySlice {
  final TaskPriority priority;
  final int count;
  final String label;

  const PrioritySlice({
    required this.priority,
    required this.count,
    required this.label,
  });
}

/// 分类扇区
class CategorySlice {
  final String id;
  final String label;
  final int count;

  const CategorySlice({
    required this.id,
    required this.label,
    required this.count,
  });
}

/// 当前任务池健康指标。
class StatsHealth {
  final int pending;
  final int overdue;
  final int weekDue;
  final int completedInPeriod;

  const StatsHealth({
    required this.pending,
    required this.overdue,
    required this.weekDue,
    required this.completedInPeriod,
  });

  static const empty = StatsHealth(
    pending: 0,
    overdue: 0,
    weekDue: 0,
    completedInPeriod: 0,
  );
}

/// 窗口内完成率
class CompletionRate {
  final int completed;
  final int total;

  const CompletionRate({required this.completed, required this.total});

  double get ratio => total == 0 ? 0 : completed / total;

  int get percent => (ratio * 100).round();
}

/// 统计页快照（内存聚合部分）
class StatsSnapshot {
  final StatsHealth health;
  final List<PrioritySlice> prioritySlices;
  final List<CategorySlice> categorySlices;
  final CompletionRate completionRate;

  const StatsSnapshot({
    required this.health,
    required this.prioritySlices,
    required this.categorySlices,
    required this.completionRate,
  });

  static StatsSnapshot empty(int days) => const StatsSnapshot(
    health: StatsHealth.empty,
    prioritySlices: [],
    categorySlices: [],
    completionRate: CompletionRate(completed: 0, total: 0),
  );
}
