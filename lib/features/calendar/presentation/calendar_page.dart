// ============================================================
// CalendarPage — 日历页(Stripe 派 1:1 还原 prototype CalendarView.tsx)
// 顶部 StatusBar + H1 + 月/周/日 SegmentedButton + 今日按钮
// + 月/周/日三视图切换 + 选中日任务列表
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
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

class _CalendarPageState extends ConsumerState<CalendarPage>
    with AutomaticKeepAliveClientMixin {
  _CalendarViewMode _viewMode = _CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _viewMode = _CalendarViewMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tasksAsync = ref.watch(taskListProvider);
    final taskIndex = ref.watch(calendarTaskIndexProvider);
    final dayTasks = ref.watch(selectedDayTasksProvider(_selectedDate));
    final tokens = context.tokens;
    final headerColor = ref.watch(headerBackgroundProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('yyyy 年 M 月').format(_selectedDate);
    final weekNum =
        ((_selectedDate.difference(DateTime(now.year, 1, 1)).inDays) / 7)
            .floor() +
        1;
    final dayLabel = DateFormat('M 月 d 日').format(_selectedDate);

    return Scaffold(
      backgroundColor: ref.watch(scaffoldBackgroundProvider),
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: headerColor,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日历',
                      style: tokens.sansSemibold(
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
                      style: tokens.mono(
                        size: 12,
                        color: tokens.fgMuted,
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
                child: tasksAsync.when(
                  data: (_) => switch (_viewMode) {
                    _CalendarViewMode.month => MonthView(
                      selectedDate: _selectedDate,
                      taskIndex: taskIndex,
                      onSelectDate: (d) => setState(() => _selectedDate = d),
                    ),
                    _CalendarViewMode.week => WeekView(
                      selectedDate: _selectedDate,
                      taskIndex: taskIndex,
                      onSelectDate: (d) => setState(() => _selectedDate = d),
                    ),
                    _CalendarViewMode.day => DayView(
                      selectedDate: _selectedDate,
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
              if (tasksAsync.hasValue)
                _SelectedDayPanel(
                  selectedDate: _selectedDate,
                  dayTasks: dayTasks,
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
    final tokens = context.tokens;
    return Material(
      color: tokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: tokens.borderStrong, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar_days, size: 14, color: tokens.fgMuted),
              const SizedBox(width: 6),
              Text(
                '今日',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> dayTasks;
  const _SelectedDayPanel({required this.selectedDate, required this.dayTasks});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cardColor = tokens.taskCardBackground;

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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: tokens.fg,
                ),
              ),
              Text(
                DateFormat('M/yyyy').format(selectedDate),
                style: tokens.mono(
                  size: 10,
                  color: tokens.fgSubtle,
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
                color: tokens.bgMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: tokens.borderStrong, width: 0.5),
              ),
              child: Center(
                child: Text(
                  '本日暂无排期日程',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.fgMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            TempoGlassSurface(
              padding: const EdgeInsets.all(12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayTasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _CalendarTaskRow(
                    task: dayTasks[index],
                    cardColor: cardColor,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarTaskRow extends ConsumerWidget {
  final Task task;
  final Color cardColor;
  const _CalendarTaskRow({required this.task, required this.cardColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(taskDetailOverlayProvider.notifier).state = true;
          context.push('/tasks/${task.id}').whenComplete(() {
            ref.read(taskDetailOverlayProvider.notifier).state = false;
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: tokens.borderStrong, width: 0.8),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: tokens.fg,
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
                            style: tokens.mono(
                              size: 10,
                              color: tokens.fgMuted,
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
                const TempoPillBadge(label: '已完成', kind: TempoBadgeKind.success)
              else
                Icon(
                  LucideIcons.chevron_right,
                  size: 14,
                  color: tokens.fgFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
