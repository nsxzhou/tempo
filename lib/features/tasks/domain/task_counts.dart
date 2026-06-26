import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import 'task.dart';

class TaskCategoryCounts {
  final int all;
  final int work;
  final int life;
  final int untagged;

  const TaskCategoryCounts({
    required this.all,
    required this.work,
    required this.life,
    required this.untagged,
  });

  static const empty = TaskCategoryCounts(
    all: 0,
    work: 0,
    life: 0,
    untagged: 0,
  );

  TaskCategoryCounts increment(String? tag) {
    if (tag == AppConstants.tagWork) {
      return TaskCategoryCounts(
        all: all + 1,
        work: work + 1,
        life: life,
        untagged: untagged,
      );
    }
    if (tag == AppConstants.tagLife) {
      return TaskCategoryCounts(
        all: all + 1,
        work: work,
        life: life + 1,
        untagged: untagged,
      );
    }
    return TaskCategoryCounts(
      all: all + 1,
      work: work,
      life: life,
      untagged: untagged + 1,
    );
  }
}

/// 任务列表统计计数（单次遍历 derived）。
class TaskCounts {
  final int pending;
  final int todayDue;
  final int overdue;
  final int weekDue;
  final int total;
  final int completed;
  final TaskCategoryCounts allCategories;
  final TaskCategoryCounts activeCategories;

  const TaskCounts({
    required this.pending,
    required this.todayDue,
    required this.overdue,
    required this.weekDue,
    required this.total,
    required this.completed,
    required this.allCategories,
    required this.activeCategories,
  });

  static const empty = TaskCounts(
    pending: 0,
    todayDue: 0,
    overdue: 0,
    weekDue: 0,
    total: 0,
    completed: 0,
    allCategories: TaskCategoryCounts.empty,
    activeCategories: TaskCategoryCounts.empty,
  );

  int get weekCount => weekDue;
  int get work => allCategories.work;
  int get life => allCategories.life;
  int get untagged => allCategories.untagged;

  factory TaskCounts.from(List<Task> tasks, {DateTime? now}) {
    if (tasks.isEmpty) return TaskCounts.empty;

    var pending = 0;
    var todayDue = 0;
    var overdue = 0;
    var weekDue = 0;
    var completed = 0;
    var allCategories = TaskCategoryCounts.empty;
    var activeCategories = TaskCategoryCounts.empty;
    final current = now ?? DateTime.now();

    for (final task in tasks) {
      allCategories = allCategories.increment(task.tag);
      if (task.isCompleted) {
        completed++;
      } else {
        pending++;
        activeCategories = activeCategories.increment(task.tag);
      }
      if (task.dueDate != null &&
          !task.isCompleted &&
          isDueOnDate(task.dueDate!, current)) {
        todayDue++;
      }
      if (task.dueDate != null &&
          isTaskOverdue(
            dueDate: task.dueDate!,
            isAllDay: task.isAllDay,
            isCompleted: task.isCompleted,
            now: current,
          )) {
        overdue++;
      }
      if (!task.isCompleted &&
          task.dueDate != null &&
          isDueInWeekRange(task.dueDate!, current)) {
        weekDue++;
      }
    }

    return TaskCounts(
      pending: pending,
      todayDue: todayDue,
      overdue: overdue,
      weekDue: weekDue,
      total: tasks.length,
      completed: completed,
      allCategories: allCategories,
      activeCategories: activeCategories,
    );
  }
}
