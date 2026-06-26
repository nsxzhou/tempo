import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../database/database.dart' as db;
import '../../tasks/domain/task.dart';
import '../domain/stats_models.dart';

class StatsRepository {
  StatsRepository(this._database);

  final db.AppDatabase _database;

  /// Drift 监听 + 按日聚合（补零空日）。
  Stream<List<DailyCompletion>> watchDailyCompletions(int days) {
    final range = _dateRange(days);
    return _database
        .watchCompletedTasksInRange(range.start, range.end)
        .map((rows) => _aggregateDaily(rows, range.start, days));
  }

  /// 内存聚合：优先级 / 分类 / 完成率。
  StatsSnapshot computeSnapshot(List<Task> tasks, int days) {
    final active = tasks.where((t) => !t.isCompleted).toList();
    final now = DateTime.now();
    final windowStart = _dateOnly(now).subtract(Duration(days: days - 1));
    final windowEnd = _dateOnly(now).add(const Duration(days: 1));

    final windowTasks = tasks.where((t) {
      final created = _dateOnly(t.createdAt);
      return !created.isBefore(windowStart) && created.isBefore(windowEnd);
    }).toList();

    var overdue = 0;
    var weekDue = 0;
    for (final task in active) {
      final due = task.dueDate;
      if (due == null) continue;
      if (isTaskOverdue(
        dueDate: due,
        isAllDay: task.isAllDay,
        isCompleted: task.isCompleted,
        now: now,
      )) {
        overdue++;
      }
      if (isDueInWeekRange(due, now)) {
        weekDue++;
      }
    }

    final priorityCounts = <TaskPriority, int>{
      TaskPriority.p0: 0,
      TaskPriority.p1: 0,
      TaskPriority.p2: 0,
      TaskPriority.p3: 0,
    };
    for (final task in active) {
      if (task.priority == TaskPriority.none) continue;
      priorityCounts[task.priority] = (priorityCounts[task.priority] ?? 0) + 1;
    }

    final prioritySlices = priorityCounts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PrioritySlice(
            priority: e.key,
            count: e.value,
            label: e.key.label ?? e.key.name.toUpperCase(),
          ),
        )
        .toList();

    var work = 0;
    var life = 0;
    var untagged = 0;
    for (final task in active) {
      switch (task.tag) {
        case AppConstants.tagWork:
          work++;
        case AppConstants.tagLife:
          life++;
        default:
          untagged++;
      }
    }

    final categorySlices = <CategorySlice>[
      if (work > 0) CategorySlice(id: 'work', label: '工作', count: work),
      if (life > 0) CategorySlice(id: 'life', label: '生活', count: life),
      if (untagged > 0)
        CategorySlice(id: 'untagged', label: '未分类', count: untagged),
    ];

    final completedInWindow = windowTasks.where((t) => t.isCompleted).length;
    final completedInPeriod = tasks.where((t) {
      final completedAt = t.completedAt;
      if (completedAt == null) return false;
      final completedDay = _dateOnly(completedAt);
      return !completedDay.isBefore(windowStart) &&
          completedDay.isBefore(windowEnd);
    }).length;

    return StatsSnapshot(
      health: StatsHealth(
        pending: active.length,
        overdue: overdue,
        weekDue: weekDue,
        completedInPeriod: completedInPeriod,
      ),
      prioritySlices: prioritySlices,
      categorySlices: categorySlices,
      completionRate: CompletionRate(
        completed: completedInWindow,
        total: windowTasks.length,
      ),
    );
  }

  List<DailyCompletion> _aggregateDaily(
    List<db.Task> rows,
    DateTime startDay,
    int days,
  ) {
    final counts = <DateTime, int>{};
    for (final row in rows) {
      final completedAt = row.completedAt;
      if (completedAt == null) continue;
      final day = _dateOnly(completedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return List.generate(days, (i) {
      final day = startDay.add(Duration(days: i));
      return DailyCompletion(date: day, count: counts[day] ?? 0);
    });
  }

  ({DateTime start, DateTime end}) _dateRange(int days) {
    final start = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    final end = _dateOnly(DateTime.now()).add(const Duration(days: 1));
    return (start: start, end: end);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
