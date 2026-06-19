// ============================================================
// CalendarPage — 日历页(Stripe 派 1:1 还原 prototype CalendarView.tsx)
// 顶部 StatusBar + H1 + 月/周/日 SegmentedButton + 今日按钮
// + 月/周/日三视图切换 + 选中日任务列表
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../../tasks/domain/task.dart';
import 'month_view.dart';
import 'week_view.dart';
import 'day_view.dart';

enum _CalendarViewMode { month, week, day }

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  _CalendarViewMode _viewMode = _CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _viewMode = _CalendarViewMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('yyyy 年 M 月').format(_selectedDate);
    final weekNum = ((_selectedDate.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;
    final dayLabel = DateFormat('M 月 d 日').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '日历',
                          style: AppTheme.sansSemibold(
                            size: 32,
                            letterSpacing: -0.8,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _viewMode == _CalendarViewMode.month
                              ? monthLabel
                              : _viewMode == _CalendarViewMode.week
                                  ? '$monthLabel · 第 $weekNum 周'
                                  : dayLabel,
                          style: AppTheme.mono(
                            size: 12,
                            color: AppTheme.fgMuted,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 视图切换 + 今日按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<_CalendarViewMode>(
                            segments: const [
                              ButtonSegment(
                                value: _CalendarViewMode.month,
                                label: Text('月'),
                              ),
                              ButtonSegment(
                                value: _CalendarViewMode.week,
                                label: Text('周'),
                              ),
                              ButtonSegment(
                                value: _CalendarViewMode.day,
                                label: Text('日'),
                              ),
                            ],
                            selected: {_viewMode},
                            onSelectionChanged: (s) =>
                                setState(() => _viewMode = s.first),
                            style: SegmentedButton.styleFrom(
                              backgroundColor: AppTheme.bgMuted,
                              selectedBackgroundColor: AppTheme.bg,
                              selectedForegroundColor: AppTheme.fg,
                              foregroundColor: AppTheme.fgMuted,
                              side: const BorderSide(
                                color: AppTheme.borderStrong,
                                width: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TodayButton(onTap: _goToToday),
                      ],
                    ),
                  ),
                  // 三视图
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: tasks.when(
                      data: (items) => switch (_viewMode) {
                        _CalendarViewMode.month => MonthView(
                            selectedDate: _selectedDate,
                            tasks: items,
                            onSelectDate: (d) =>
                                setState(() => _selectedDate = d),
                          ),
                        _CalendarViewMode.week => WeekView(
                            selectedDate: _selectedDate,
                            tasks: items,
                            onSelectDate: (d) =>
                                setState(() => _selectedDate = d),
                          ),
                        _CalendarViewMode.day => DayView(
                            selectedDate: _selectedDate,
                            tasks: items,
                            onChange: (d) => setState(() => _selectedDate = d),
                          ),
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(child: Text('加载失败:$e')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 选中日任务列表
                  tasks.when(
                    data: (items) => _SelectedDayPanel(
                      selectedDate: _selectedDate,
                      tasks: items,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderStrong, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar_days, size: 14, color: AppTheme.fgMuted),
              SizedBox(width: 6),
              Text(
                '今日',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends ConsumerWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  const _SelectedDayPanel({required this.selectedDate, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return isDueOnDate(t.dueDate!, selectedDate);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '待办日程 (${dayTasks.length} 项)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                DateFormat('M/yyyy').format(selectedDate),
                style: AppTheme.mono(
                  size: 10,
                  color: AppTheme.fgSubtle,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bgMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.borderStrong,
                  width: 0.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Text(
                  '本日暂无排期日程',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.fgMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...dayTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CalendarTaskRow(task: t),
                )),
        ],
      ),
    );
  }
}

class _CalendarTaskRow extends ConsumerWidget {
  final Task task;
  const _CalendarTaskRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppTheme.bg,
      child: InkWell(
        onTap: () => context.push('/tasks/${task.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderStrong, width: 0.8),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (task.priority.value != 0)
                          TempoPillBadge(
                            label: 'P${task.priority.value - 1}',
                            kind: switch (task.priority.value) {
                              1 => TempoBadgeKind.p0,
                              2 => TempoBadgeKind.p1,
                              3 => TempoBadgeKind.p2,
                              _ => TempoBadgeKind.p3,
                            },
                          ),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm').format(task.dueDate!),
                            style: AppTheme.mono(
                              size: 10,
                              color: AppTheme.fgMuted,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (task.isCompleted)
                TempoPillBadge(
                  label: '已完成',
                  kind: TempoBadgeKind.success,
                )
              else
                const Icon(
                  LucideIcons.chevron_right,
                  size: 14,
                  color: AppTheme.fgFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
