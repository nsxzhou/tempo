import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';
import '../domain/task_counts.dart';
import 'widgets/task_tile.dart';

enum TaskScope { pending, overdue, week, all }

/// 判断重复任务今日是否已打卡。
bool _isRecurringTaskCompletedToday({
  required Task task,
  required List<TaskCompletion> completions,
  required DateTime now,
}) {
  if (!task.isRecurring) return false;
  final today = calendarDay(now);
  return completions.any(
    (c) => c.taskId == task.id && c.occurrenceDate == today,
  );
}

class TaskListGroups {
  final List<Task> active;
  final List<Task> completed;

  const TaskListGroups({required this.active, required this.completed});
}

class TaskFilterSnapshot {
  final TaskScopeCounts scopeCounts;
  final TaskListGroups groups;

  const TaskFilterSnapshot({required this.scopeCounts, required this.groups});
}

typedef TaskFilterKey = ({TaskScope scope, String search});

final taskFilterSnapshotProvider =
    Provider.family<TaskFilterSnapshot, TaskFilterKey>((ref, key) {
      final allTasks = ref.watch(displayTaskListProvider);
      final completions = ref.watch(taskCompletionsProvider).valueOrNull ?? [];
      return buildTaskFilterSnapshot(
        allTasks: allTasks,
        scope: key.scope,
        searchQuery: key.search,
        completions: completions,
      );
    });

TaskFilterSnapshot buildTaskFilterSnapshot({
  required List<Task> allTasks,
  required TaskScope scope,
  required String searchQuery,
  List<TaskCompletion> completions = const [],
}) {
  final searched = <Task>[];
  final active = <Task>[];
  final completed = <Task>[];
  final now = DateTime.now();
  final q = searchQuery.trim().toLowerCase();

  for (final task in allTasks) {
    if (!matchesTaskSearch(task, q)) continue;
    searched.add(task);
    if (!matchesTaskScope(task, scope, now, completions)) continue;
    if (task.isCompleted) {
      completed.add(task);
    } else {
      active.add(task);
    }
  }

  return TaskFilterSnapshot(
    scopeCounts: TaskScopeCounts.from(searched, now: now, completions: completions),
    groups: TaskListGroups(active: active, completed: completed),
  );
}

bool matchesTaskSearch(Task task, String q) {
  if (q.isEmpty) return true;
  return task.title.toLowerCase().contains(q) ||
      (task.description?.toLowerCase().contains(q) ?? false);
}

bool matchesTaskScope(
  Task task,
  TaskScope scope,
  DateTime now, [
  List<TaskCompletion> completions = const [],
]) {
  final due = task.dueDate;
  final ended = task.isRecurrenceEnded(now);
  // 判断重复任务今日是否已完成
  final effectivelyCompleted = task.isCompleted ||
      _isRecurringTaskCompletedToday(
        task: task,
        completions: completions,
        now: now,
      );
  return switch (scope) {
    TaskScope.pending => !effectivelyCompleted && !ended,
    TaskScope.overdue =>
      !ended &&
          due != null &&
          isTaskOverdue(
            dueDate: due,
            isAllDay: task.isAllDay,
            isCompleted: effectivelyCompleted,
            now: now,
          ),
    TaskScope.week =>
      !effectivelyCompleted &&
          !ended &&
          due != null &&
          isDueInWeekRange(due, now),
    TaskScope.all => true,
  };
}

class TaskScopeSection extends ConsumerWidget {
  final TaskScope scope;
  final String searchQuery;
  final ValueChanged<TaskScope> onScopeChanged;

  const TaskScopeSection({
    super.key,
    required this.scope,
    required this.searchQuery,
    required this.onScopeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      taskFilterSnapshotProvider((scope: scope, search: searchQuery)),
    );
    final counts = snapshot.scopeCounts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: TempoGlassSurface(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TaskFilterPill(
                label: '待处理',
                count: counts.pending,
                selected: scope == TaskScope.pending,
                onTap: () => onScopeChanged(TaskScope.pending),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TaskFilterPill(
                label: '逾期',
                count: counts.overdue,
                selected: scope == TaskScope.overdue,
                tone: counts.overdue > 0
                    ? TaskFilterPillTone.danger
                    : TaskFilterPillTone.neutral,
                onTap: () => onScopeChanged(TaskScope.overdue),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TaskFilterPill(
                label: '本周',
                count: counts.week,
                selected: scope == TaskScope.week,
                onTap: () => onScopeChanged(TaskScope.week),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TaskFilterPill(
                label: '全部',
                count: counts.all,
                selected: scope == TaskScope.all,
                onTap: () => onScopeChanged(TaskScope.all),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TaskFilterPillTone { neutral, danger }

class TaskFilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final TaskFilterPillTone tone;

  const TaskFilterPill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.tone = TaskFilterPillTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final danger = tone == TaskFilterPillTone.danger;
    final bg = selected
        ? (danger ? AppTheme.priorityP0Bg : t.fg)
        : (danger ? AppTheme.priorityP0Bg : t.bgMuted);
    final fg = selected
        ? (danger ? AppTheme.priorityP0 : t.bg)
        : (danger ? AppTheme.priorityP0 : t.fgSecondary);
    final border = selected
        ? (danger ? AppTheme.priorityP0Border : t.fg)
        : (danger ? AppTheme.priorityP0Border : t.borderStrong);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          curve: AppTheme.curveOrganic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: border, width: 0.7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: t.sansSemibold(size: 12, color: fg, letterSpacing: 0),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: t.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: fg.withValues(alpha: selected ? 0.78 : 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskListSection extends ConsumerWidget {
  final TaskScope scope;
  final String searchQuery;
  final void Function(Task) onTap;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  const TaskListSection({
    super.key,
    required this.scope,
    required this.searchQuery,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final snapshot = ref.watch(
      taskFilterSnapshotProvider((scope: scope, search: searchQuery)),
    );
    final groups = snapshot.groups;
    final async = ref.watch(taskListProvider);
    final backgrounds = ref.watch(taskBackgroundMapProvider);
    final aiEnhancementState = ref.watch(taskAiEnhancementStateProvider);
    final streakMap = ref.watch(taskStreakMapProvider);
    final taskMap = ref.watch(taskMapProvider);

    if (!async.hasValue && !async.hasError) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (async.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text('加载失败:${async.error}')),
        ),
      );
    }

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
                final raw = taskMap[task.id];
                final now = DateTime.now();
                return RepaintBoundary(
                  child: TaskTile(
                    key: ValueKey('task-${task.id}'),
                    task: task,
                    onTap: () => onTap(task),
                    onToggleComplete: () => onToggle(task),
                    showDelete: true,
                    onDelete: () => onDelete(task),
                    backgroundImagePath: backgrounds[task.id]?.imagePath,
                    aiEnhancementStatus: aiEnhancementState[task.id],
                    streakCount: streakMap[task.id]?.current,
                    showRecurring:
                        (raw?.isRecurring ?? false) &&
                        !(raw?.isRecurrenceEnded(now) ?? false),
                    showEnded: raw?.isRecurrenceEnded(now) ?? false,
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
                    backgroundImagePath: backgrounds[task.id]?.imagePath,
                    aiEnhancementStatus: aiEnhancementState[task.id],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
