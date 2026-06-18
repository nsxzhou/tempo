// ============================================================
// MonthView — 月视图（table_calendar + 圆点标记 + 当日任务列表）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/widgets/task_tile.dart';

/// 月视图：使用 table_calendar 显示任务分布，点击日期展开当日任务。
class MonthView extends ConsumerStatefulWidget {
  final List<Task> tasks;

  const MonthView({super.key, required this.tasks});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(DateTime.now());
  }

  /// 将 DateTime 规范化为当天 00:00:00（去掉时分秒）。
  DateTime _normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// 获取某天的任务列表。
  List<Task> _tasksForDay(DateTime day) {
    final normalized = _normalizeDate(day);
    return widget.tasks.where((t) {
      if (t.dueDate == null) return false;
      return _normalizeDate(t.dueDate!) == normalized;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks =
        _selectedDay != null ? _tasksForDay(_selectedDay!) : <Task>[];

    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) {
            _focusedDay = focused;
          },
          eventLoader: _tasksForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markerMargin: const EdgeInsets.symmetric(horizontal: 1),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(height: 1),
        // 当日任务列表
        Expanded(
          child: selectedTasks.isEmpty
              ? EmptyState(
                  icon: Icons.event_available,
                  title: _selectedDay != null
                      ? '${DateFormat('M月d日').format(_selectedDay!)} 暂无任务'
                      : '选择日期查看任务',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = selectedTasks[index];
                    return TaskTile(
                      task: task,
                      onToggleComplete: () => _toggleTask(task),
                      onTap: () => context.push('/tasks/${task.id}'),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _toggleTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.toggleComplete(task.id);

    final notificationService = ref.read(notificationServiceProvider);
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    if (updated.isCompleted) {
      await notificationService.cancelTaskReminders(task.id);
    } else {
      await notificationService.scheduleTaskReminder(updated);
    }
  }

  Future<void> _deleteTask(Task task) async {
    await ref.read(taskRepositoryProvider).deleteTask(task.id);
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.cancelTaskReminders(task.id);
  }
}
