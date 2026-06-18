// ============================================================
// WeekView — 周视图（横向时间轴 + 任务块按 dueDate 定位）
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tasks/domain/task.dart';

/// 周视图：横向 7 天时间轴，任务块按 dueDate 的时间定位。
class WeekView extends StatefulWidget {
  final List<Task> tasks;

  const WeekView({super.key, required this.tasks});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late DateTime _weekStart;
  final _scrollController = ScrollController();
  final double _hourHeight = 60.0;
  final int _startHour = 7;
  final int _endHour = 22;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    // 滚动到当前时间附近
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final offset = (now.hour - _startHour) * _hourHeight;
      if (offset > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 获取周一日期。
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  /// 获取某天的任务。
  List<Task> _tasksForDay(DateTime day) {
    return widget.tasks.where((t) {
      if (t.dueDate == null) return false;
      final taskDay = DateTime(
        t.dueDate!.year,
        t.dueDate!.month,
        t.dueDate!.day,
      );
      final compareDay = DateTime(day.year, day.month, day.day);
      return taskDay == compareDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Column(
      children: [
        // 周导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                    _weekStart = _weekStart.subtract(const Duration(days: 7))),
              ),
              Text(
                '${DateFormat('M/d').format(_weekStart)} - ${DateFormat('M/d').format(_weekStart.add(const Duration(days: 6)))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() =>
                    _weekStart = _weekStart.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        // 星期标题行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 40), // 时间列宽度
              ...days.map((day) {
                final isToday = _isSameDay(day, DateTime.now());
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          _weekdayLabel(day.weekday),
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday
                                ? AppTheme.primaryColor
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? AppTheme.primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        // 时间轴 + 任务块
        Expanded(
          child: widget.tasks.isEmpty
              ? const EmptyState(
                  icon: Icons.view_week,
                  title: '本周暂无有时间的任务',
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: (_endHour - _startHour) * _hourHeight,
                    child: Row(
                      children: [
                        // 时间列
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: List.generate(
                              _endHour - _startHour,
                              (i) => SizedBox(
                                height: _hourHeight,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 4, top: 2),
                                    child: Text(
                                      '${_startHour + i}:00',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 每天的任务列
                        ...days.map((day) => _buildDayColumn(day)),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// 构建某天的任务列。
  Widget _buildDayColumn(DateTime day) {
    final dayTasks = _tasksForDay(day);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Stack(
          children: [
            // 网格线
            Column(
              children: List.generate(
                _endHour - _startHour,
                (i) => Container(
                  height: _hourHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.grey.shade100, width: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            // 任务块
            ...dayTasks.map((task) => _buildTaskBlock(task)),
          ],
        ),
      ),
    );
  }

  /// 构建任务块。
  Positioned _buildTaskBlock(Task task) {
    final dueDate = task.dueDate!;
    final hour = dueDate.hour + dueDate.minute / 60.0;
    final topOffset = (hour - _startHour) * _hourHeight;
    final blockHeight = 40.0; // 固定高度

    final priorityColor = AppTheme.priorityColor(task.priority.value);
    final isCompleted = task.isCompleted;

    return Positioned(
      top: topOffset.clamp(0, (_endHour - _startHour) * _hourHeight - blockHeight),
      left: 2,
      right: 2,
      height: blockHeight,
      child: GestureDetector(
        onTap: () => context.push('/tasks/${task.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.grey.shade200
                : priorityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: priorityColor, width: 3),
            ),
          ),
          child: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isCompleted ? Colors.grey : Colors.black87,
              decoration:
                  isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      1 => '一',
      2 => '二',
      3 => '三',
      4 => '四',
      5 => '五',
      6 => '六',
      7 => '日',
      _ => '',
    };
  }
}
