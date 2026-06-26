import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import 'task.dart';

/// 任务列表统计计数（单次遍历 derived）。
class TaskCounts {
  final int pending;
  final int overdue;
  final int weekCount;
  final int total;
  final int work;
  final int life;

  const TaskCounts({
    required this.pending,
    required this.overdue,
    required this.weekCount,
    required this.total,
    required this.work,
    required this.life,
  });

  static const empty = TaskCounts(
    pending: 0,
    overdue: 0,
    weekCount: 0,
    total: 0,
    work: 0,
    life: 0,
  );

  factory TaskCounts.from(List<Task> tasks, {DateTime? now}) {
    if (tasks.isEmpty) return TaskCounts.empty;

    var pending = 0;
    var overdue = 0;
    var weekCount = 0;
    var work = 0;
    var life = 0;
    final current = now ?? DateTime.now();

    for (final task in tasks) {
      if (!task.isCompleted) pending++;
      if (task.dueDate != null &&
          isTaskOverdue(
            dueDate: task.dueDate!,
            isAllDay: task.isAllDay,
            isCompleted: task.isCompleted,
            now: current,
          )) {
        overdue++;
      }
      if (task.dueDate != null && isDueInWeekRange(task.dueDate!, current)) {
        weekCount++;
      }
      if (task.tag == AppConstants.tagWork) work++;
      if (task.tag == AppConstants.tagLife) life++;
    }

    return TaskCounts(
      pending: pending,
      overdue: overdue,
      weekCount: weekCount,
      total: tasks.length,
      work: work,
      life: life,
    );
  }
}
