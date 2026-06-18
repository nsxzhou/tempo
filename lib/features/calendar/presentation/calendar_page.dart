// ============================================================
// CalendarPage — 日历页（月/周切换 + 左右滑动）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tasks/domain/task.dart';
import 'month_view.dart';
import 'week_view.dart';

/// 日历页：月视图 + 周视图切换 + 左右滑动。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  _CalendarViewMode _viewMode = _CalendarViewMode.month;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          _ViewModeToggle(
            mode: _viewMode,
            onChanged: (mode) => setState(() => _viewMode = mode),
          ),
        ],
      ),
      body: tasks.when(
        data: (items) {
          // 过滤出有 dueDate 的任务
          final tasksWithDates =
              items.where((t) => t.dueDate != null).toList();
          if (tasksWithDates.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: '暂无有截止日期的任务',
              subtitle: '为任务设置截止时间后，会在此处显示',
            );
          }
          return switch (_viewMode) {
            _CalendarViewMode.month => MonthView(tasks: tasksWithDates),
            _CalendarViewMode.week => WeekView(tasks: tasksWithDates),
          };
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
      ),
    );
  }
}

/// 日历视图模式。
enum _CalendarViewMode { month, week }

/// 月/周切换按钮。
class _ViewModeToggle extends StatelessWidget {
  final _CalendarViewMode mode;
  final ValueChanged<_CalendarViewMode> onChanged;

  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SegmentedButton<_CalendarViewMode>(
        segments: const [
          ButtonSegment(
            value: _CalendarViewMode.month,
            icon: Icon(Icons.calendar_month, size: 18),
            label: Text('月'),
          ),
          ButtonSegment(
            value: _CalendarViewMode.week,
            icon: Icon(Icons.view_week, size: 18),
            label: Text('周'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (set) => onChanged(set.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
