// ============================================================
// TasksPage — 任务列表页(Stripe 派 1:1 还原 prototype TasksView.tsx)
// 顶部 StatusBar + H1 + Bento 4 卡过滤 + 工作/生活 segmented + 列表
// + 浮动 Mic/Plus 双按钮
// 业务逻辑完全保留:语音录音/解析、草稿卡、撤回 Snackbar、Repository
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/task.dart';
import 'widgets/quick_create_sheet.dart';
import 'widgets/task_tile.dart';
import 'widgets/voice_overlay.dart';

enum _TimeFilter { today, week, overdue, all }

enum _CategoryFilter { all, work, life }

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with AutomaticKeepAliveClientMixin {
  bool _showVoiceOverlay = false;
  bool _showQuickCreate = false;
  Task? _lastDeletedTask;

  _TimeFilter _timeFilter = _TimeFilter.today;
  _CategoryFilter _categoryFilter = _CategoryFilter.all;
  bool _showSearch = false;
  String _debouncedSearchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _debouncedSearchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scaffoldBg = ref.watch(scaffoldBackgroundProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: SlidableAutoCloseBehavior(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(
                        child: _BentoStatsSection(
                          timeFilter: _timeFilter,
                          onTimeFilterChanged: (filter) =>
                              setState(() => _timeFilter = filter),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _CategoryFilterSection(
                          categoryFilter: _categoryFilter,
                          onCategoryFilterChanged: (filter) =>
                              setState(() => _categoryFilter = filter),
                        ),
                      ),
                      _TaskListSection(
                        timeFilter: _timeFilter,
                        categoryFilter: _categoryFilter,
                        searchQuery: _debouncedSearchQuery,
                        onTap: _navigateToDetail,
                        onToggle: _toggleTask,
                        onDelete: _deleteTask,
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 浮动按钮（语音/快速创建 overlay 打开时隐藏）
          if (!_showVoiceOverlay && !_showQuickCreate)
            Positioned(
              right: 20,
              bottom: 120,
              child: _FloatingActions(
                onVoice: () {
                  ref.read(shellTabBarVisibleProvider.notifier).state = false;
                  setState(() => _showVoiceOverlay = true);
                },
                onAdd: _openQuickCreate,
              ),
            ),
          // 语音录入浮层
          if (_showVoiceOverlay)
            VoiceOverlay(
              onClose: () {
                setState(() => _showVoiceOverlay = false);
                ref.read(shellTabBarVisibleProvider.notifier).state = true;
              },
              onNeedDraftConfirm: (draft) {
                unawaited(QuickCreateSheet.showPrefill(context, draft: draft));
              },
            ),
        ],
      ),
    );
  }

  // ══════════════ UI 部分 ══════════════

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateText = DateFormat('M 月 d 日 · EEEE', 'zh_CN').format(now);
    final tokens = context.tokens;
    final headerColor = ref.watch(headerBackgroundProvider);
    return Container(
      color: headerColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODO',
                  style: tokens.sansSemibold(
                    size: 32,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateText,
                  style: tokens.mono(
                    size: 12,
                    color: tokens.fgMuted,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showSearch = !_showSearch),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _showSearch ? tokens.bgSubtle : tokens.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showSearch ? tokens.fg : tokens.borderStrong,
                  width: 0.8,
                ),
              ),
              child: Icon(
                LucideIcons.search,
                size: 14,
                color: tokens.fgSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final t = context.tokens;
    return AnimatedSize(
      duration: AppTheme.durationMedium,
      curve: AppTheme.curveOrganic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: AnimatedOpacity(
        duration: AppTheme.durationMedium,
        curve: AppTheme.curveOrganic,
        opacity: _showSearch ? 1 : 0,
        child: _showSearch
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bgMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, size: 14, color: t.fgSubtle),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: '检索日常任务或内容…',
                            hintStyle: t.mono(size: 12, color: t.fgSubtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }

  // ══════════════ 业务逻辑(完全保留) ══════════════

  Future<void> _toggleTask(Task task) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = await repository.toggleComplete(task.id);
      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        unawaited(notificationService.cancelTaskReminders(task.id));
      } else {
        unawaited(notificationService.scheduleTaskReminder(updated));
      }
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '操作失败:$error');
    }
  }

  void _navigateToDetail(Task task) {
    context.push('/tasks/${task.id}');
  }

  Future<void> _deleteTask(Task task) async {
    _lastDeletedTask = task;
    try {
      await ref.read(taskRepositoryProvider).deleteTask(task.id);
      unawaited(
        ref.read(notificationServiceProvider).cancelTaskReminders(task.id),
      );
      if (!mounted) return;
      TempoSnackbar.show(
        context,
        message: '已删除:${task.title}',
        undoLabel: '撤回',
        onUndo: () async {
          if (_lastDeletedTask != null) {
            await ref
                .read(taskRepositoryProvider)
                .createTask(
                  title: _lastDeletedTask!.title,
                  description: _lastDeletedTask!.description,
                  dueDate: _lastDeletedTask!.dueDate,
                  priority: _lastDeletedTask!.priority,
                  creationSource: _lastDeletedTask!.creationSource,
                  tag: _lastDeletedTask!.tag,
                );
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '删除失败:$error');
    }
  }

  Future<void> _openQuickCreate() async {
    ref.read(shellTabBarVisibleProvider.notifier).state = false;
    setState(() => _showQuickCreate = true);

    await QuickCreateSheet.show(context);

    if (!mounted) return;
    setState(() => _showQuickCreate = false);
    ref.read(shellTabBarVisibleProvider.notifier).state = true;
  }
}

class _TaskListGroups {
  final List<Task> active;
  final List<Task> completed;

  const _TaskListGroups({required this.active, required this.completed});
}

_TaskListGroups _filterTaskGroups({
  required List<Task> allTasks,
  required _TimeFilter timeFilter,
  required _CategoryFilter categoryFilter,
  required String searchQuery,
}) {
  final active = <Task>[];
  final completed = <Task>[];
  final now = DateTime.now();
  final q = searchQuery.trim().toLowerCase();

  for (final task in allTasks) {
    if (q.isNotEmpty &&
        !task.title.toLowerCase().contains(q) &&
        !(task.description?.toLowerCase().contains(q) ?? false)) {
      continue;
    }

    final due = task.dueDate;
    final matchesTime = switch (timeFilter) {
      _TimeFilter.today => !task.isCompleted,
      _TimeFilter.week => due != null && isDueInWeekRange(due, now),
      _TimeFilter.overdue =>
        due != null &&
            isTaskOverdue(
              dueDate: due,
              isAllDay: task.isAllDay,
              isCompleted: task.isCompleted,
              now: now,
            ),
      _TimeFilter.all => true,
    };
    if (!matchesTime) continue;

    final matchesCategory = switch (categoryFilter) {
      _CategoryFilter.all => true,
      _CategoryFilter.work => task.tag == AppConstants.tagWork,
      _CategoryFilter.life => task.tag == AppConstants.tagLife,
    };
    if (!matchesCategory) continue;

    if (task.isCompleted) {
      completed.add(task);
    } else {
      active.add(task);
    }
  }

  return _TaskListGroups(active: active, completed: completed);
}

class _BentoStatsSection extends ConsumerWidget {
  final _TimeFilter timeFilter;
  final ValueChanged<_TimeFilter> onTimeFilterChanged;

  const _BentoStatsSection({
    required this.timeFilter,
    required this.onTimeFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(taskCountsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TempoGlassSurface(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _BentoCard(
              label: '今日待办',
              value: '${counts.pending}',
              unit: '项未完成',
              selected: timeFilter == _TimeFilter.today,
              dotColor: AppTheme.priorityP2,
              onTap: () => onTimeFilterChanged(_TimeFilter.today),
            ),
            _BentoCard(
              label: '已过期',
              value: '${counts.overdue}',
              unit: '项超期',
              selected: timeFilter == _TimeFilter.overdue,
              dotColor: counts.overdue > 0
                  ? AppTheme.priorityP0
                  : context.tokens.fgMuted,
              dotPulse: counts.overdue > 0,
              errorTone: counts.overdue > 0,
              onTap: () => onTimeFilterChanged(_TimeFilter.overdue),
            ),
            _BentoCard(
              label: '本周安排',
              value: '${counts.weekCount}',
              unit: '项总代办',
              selected: timeFilter == _TimeFilter.week,
              dotColor: context.tokens.fgFaint,
              onTap: () => onTimeFilterChanged(_TimeFilter.week),
            ),
            _BentoCard(
              label: '全部任务',
              value: '${counts.total}',
              unit: '项总代办',
              selected: timeFilter == _TimeFilter.all,
              dotColor: AppTheme.success,
              onTap: () => onTimeFilterChanged(_TimeFilter.all),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterSection extends ConsumerWidget {
  final _CategoryFilter categoryFilter;
  final ValueChanged<_CategoryFilter> onCategoryFilterChanged;

  const _CategoryFilterSection({
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final counts = ref.watch(taskCountsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SegmentedButton<_CategoryFilter>(
        segments: [
          ButtonSegment(
            value: _CategoryFilter.all,
            label: _segmentLabel(context, '全部', counts.total),
          ),
          ButtonSegment(
            value: _CategoryFilter.work,
            label: _segmentLabel(context, '工作', counts.work),
          ),
          ButtonSegment(
            value: _CategoryFilter.life,
            label: _segmentLabel(context, '生活', counts.life),
          ),
        ],
        selected: {categoryFilter},
        onSelectionChanged: (s) => onCategoryFilterChanged(s.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: t.bgMuted,
          selectedBackgroundColor: t.bg,
          selectedForegroundColor: t.fg,
          foregroundColor: t.fgSecondary,
          side: BorderSide(color: t.borderStrong, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
    );
  }
}

Widget _segmentLabel(BuildContext context, String label, int count) {
  final t = context.tokens;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: t.fg.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$count',
          style: t.mono(size: 9, weight: FontWeight.w600, color: t.fgMuted),
        ),
      ),
    ],
  );
}

class _TaskListSection extends ConsumerWidget {
  final _TimeFilter timeFilter;
  final _CategoryFilter categoryFilter;
  final String searchQuery;
  final void Function(Task) onTap;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  const _TaskListSection({
    required this.timeFilter,
    required this.categoryFilter,
    required this.searchQuery,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final t = context.tokens;

    return tasksAsync.when(
      data: (allTasks) {
        final groups = _filterTaskGroups(
          allTasks: allTasks,
          timeFilter: timeFilter,
          categoryFilter: categoryFilter,
          searchQuery: searchQuery,
        );

        if (groups.active.isEmpty && groups.completed.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Center(
                child: Text(
                  '暂无任务',
                  style: TextStyle(fontSize: 13, color: t.fgMuted),
                ),
              ),
            ),
          );
        }

        final active = groups.active;
        final completed = groups.completed;

        return SliverMainAxisGroup(
          slivers: [
            if (active.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: TempoSectionHeader(label: '待办 · ${active.length}'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverList.separated(
                  itemCount: active.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = active[index];
                    return RepaintBoundary(
                      child: TaskTile(
                        key: ValueKey('task-${task.id}'),
                        task: task,
                        onTap: () => onTap(task),
                        onToggleComplete: () => onToggle(task),
                        showDelete: true,
                        onDelete: () => onDelete(task),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: TempoSectionHeader(
                  label: '已完成 · ${completed.length}',
                  color: t.fgSubtle,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverList.separated(
                  itemCount: completed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = completed[index];
                    return RepaintBoundary(
                      child: TaskTile(
                        key: ValueKey('task-${task.id}'),
                        task: task,
                        onTap: () => onTap(task),
                        onToggleComplete: () => onToggle(task),
                        showDelete: true,
                        onDelete: () => onDelete(task),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text('加载失败:$error')),
        ),
      ),
    );
  }
}

// ══════════════ 子组件 ══════════════

class _BentoCard extends ConsumerStatefulWidget {
  final String label;
  final String value;
  final String unit;
  final bool selected;
  final bool errorTone;
  final bool dotPulse;
  final Color dotColor;
  final VoidCallback onTap;

  const _BentoCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.selected,
    required this.dotColor,
    required this.onTap,
    this.errorTone = false,
    this.dotPulse = false,
  });

  @override
  ConsumerState<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends ConsumerState<_BentoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.dotPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dotPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.dotPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasGlass = ref.watch(hasCustomBackgroundProvider);
    final Color fill;
    if (widget.selected) {
      fill = widget.errorTone
          ? const Color(0xFF450A0A)
          : (hasGlass ? t.fg.withValues(alpha: 0.85) : t.fg);
    } else if (widget.errorTone) {
      fill = hasGlass
          ? const Color(0xFFFEF2F2).withValues(alpha: 0.72)
          : const Color(0xFFFEF2F2);
    } else if (hasGlass) {
      fill = t.taskCardBackground;
    } else {
      fill = t.bg;
    }
    final fg = widget.selected
        ? (widget.errorTone ? const Color(0xFFFEE2E2) : t.bg)
        : (widget.errorTone ? const Color(0xFFB91C1C) : t.fg);
    final subtle = widget.selected
        ? (widget.errorTone ? const Color(0xFFFCA5A5) : t.fgMuted)
        : t.fgMuted;
    final border = widget.selected
        ? fill
        : (widget.errorTone ? const Color(0xFFFECACA) : t.borderStrong);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedScale(
          scale: widget.selected ? 1.0 : 0.98,
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveOrganic,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: border, width: 0.8),
              boxShadow: !widget.selected
                  ? [
                      BoxShadow(
                        color: t.fg.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: AppTheme.mono(
                        size: 9,
                        weight: FontWeight.w700,
                        color: subtle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    _buildDot(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.value,
                      style: AppTheme.mono(
                        size: 22,
                        weight: FontWeight.w700,
                        color: fg,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        widget.unit,
                        style: AppTheme.mono(
                          size: 9,
                          weight: FontWeight.w700,
                          color: subtle,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot() {
    if (!widget.dotPulse) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.dotColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        return Transform.scale(
          scale: 1.0 + t * 0.35,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.dotColor.withValues(alpha: 0.55 + t * 0.45),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _FloatingActions extends StatelessWidget {
  final VoidCallback onVoice;
  final VoidCallback onAdd;
  const _FloatingActions({required this.onVoice, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Fab(
          key: const ValueKey('voice-fab'),
          icon: LucideIcons.mic,
          onTap: onVoice,
        ),
        const SizedBox(height: 12),
        _Fab(icon: LucideIcons.plus, onTap: onAdd, filled: true),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _Fab({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: filled ? t.fg : t.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: filled ? t.fg : t.borderStrong, width: 0.8),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: filled ? t.bg : t.fg),
        ),
      ),
    );
  }
}
