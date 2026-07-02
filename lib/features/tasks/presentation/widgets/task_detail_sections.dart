import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/task_filter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../data/task_background_repository.dart';
import '../../domain/recurrence_engine.dart';
import '../../domain/recurrence_models.dart';
import '../../domain/task.dart';
import '../../domain/task_list_builder.dart';
import '../task_detail_helpers.dart';
import 'recurrence_series_timeline.dart';
import 'streak_summary_card.dart';
import 'task_background_image.dart';

class TaskDetailTitleBlock extends StatelessWidget {
  final Task task;
  final TaskBackground? background;

  const TaskDetailTitleBlock({
    super.key,
    required this.task,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (task.priority != TaskPriority.none)
              TempoPillBadge(
                label: 'P${task.priority.value - 1} 级别',
                kind: switch (task.priority) {
                  TaskPriority.p0 => TempoBadgeKind.p0,
                  TaskPriority.p1 => TempoBadgeKind.p1,
                  TaskPriority.p2 => TempoBadgeKind.p2,
                  TaskPriority.p3 => TempoBadgeKind.p3,
                  _ => TempoBadgeKind.neutral,
                },
                fontSize: 10,
              ),
            if (task.tag == AppConstants.tagWork)
              const TempoPillBadge(
                label: '@工作',
                kind: TempoBadgeKind.tag,
                uppercase: false,
                fontSize: 10,
              )
            else if (task.tag == AppConstants.tagLife)
              const TempoPillBadge(
                label: '@生活',
                kind: TempoBadgeKind.tag,
                uppercase: false,
                fontSize: 10,
              ),
            if (task.creationSource != 'text')
              TempoPillBadge(
                label: '#${taskDetailSourceTag(task.creationSource)}',
                kind: TempoBadgeKind.neutral,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: t.italicSerif(size: 32, height: 1.1, letterSpacing: -0.8),
        ),
      ],
    );

    final imagePath = background?.imagePath;
    if (imagePath == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: content,
      );
    }

    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: AppTheme.shadowSm,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: t.borderStrong, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: TaskBackgroundImage(
                  path: imagePath,
                  errorColor: t.taskCardBackground,
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: t.bg.withValues(alpha: 0.32)),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        t.bg.withValues(alpha: 0.20),
                        t.bg.withValues(alpha: 0.02),
                        t.fg.withValues(alpha: 0.08),
                      ],
                      stops: const [0, 0.54, 1],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 156),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailProperties extends ConsumerWidget {
  final Task task;
  final String? listName;

  const TaskDetailProperties({
    super.key,
    required this.task,
    required this.listName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cardColor = ref.watch(taskCardBackgroundProvider);
    final now = DateTime.now();
    final dueDisplay = resolveTaskDueDisplay(ref, task, now);
    final displayDue = dueDisplay.dueDate;
    final isOverdue = displayDue != null &&
        isTaskOverdue(
          dueDate: displayDue,
          isAllDay: dueDisplay.isAllDay,
          isCompleted: task.isCompleted,
          now: now,
        );
    final showDueBadge = !task.isCompleted &&
        displayDue != null &&
        (isOverdue || isDueOnDate(displayDue, now));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TempoGlassSurface(
        blur: false,
        fillColor: cardColor,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            TempoPropertyRow(
              icon: LucideIcons.calendar,
              label: dueDisplay.label,
              value: displayDue != null
                  ? Row(
                      children: [
                        Text(
                          formatTaskDueDetail(
                            dueDate: displayDue,
                            isAllDay: dueDisplay.isAllDay,
                          ),
                          style: t.mono(size: 13, weight: FontWeight.w500),
                        ),
                        if (showDueBadge) ...[
                          const SizedBox(width: 8),
                          TempoPillBadge(
                            label: isOverdue ? '已延误' : '即将截止',
                            kind: isOverdue
                                ? TempoBadgeKind.error
                                : TempoBadgeKind.p1,
                          ),
                        ],
                      ],
                    )
                  : Text(
                      '未设置',
                      style: TextStyle(fontSize: 13, color: t.fgSubtle),
                    ),
            ),
            TempoPropertyRow(
              icon: LucideIcons.folder,
              label: '归属',
              value: Text(
                listName ?? '加载中…',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({DateTime? dueDate, DateTime? occurrenceDate, bool isAllDay, String label})
resolveTaskDueDisplay(
  WidgetRef ref,
  Task task,
  DateTime now,
) {
  if (!task.isRecurring) {
    final occDate = task.dueDate != null
        ? RecurrenceEngine.calendarDay(task.dueDate!)
        : null;
    return (
      dueDate: task.dueDate,
      occurrenceDate: occDate,
      isAllDay: task.isAllDay,
      label: '截止',
    );
  }

  const engine = RecurrenceEngine();
  final completions = ref.watch(taskCompletionsProvider).valueOrNull ?? [];
  final exceptions =
      ref.watch(taskRecurrenceExceptionsProvider).valueOrNull ?? [];
  final next = engine.nextOccurrence(
    task,
    completions: completions.forTask(task.id, (c) => c.taskId),
    exceptions: exceptions.forTask(task.id, (e) => e.taskId),
    now: now,
  );
  if (next?.effectiveDue == null) {
    return (dueDate: null, occurrenceDate: null, isAllDay: task.isAllDay, label: '下次');
  }
  return (
    dueDate: next!.effectiveDue,
    occurrenceDate: next.occurrenceDate,
    isAllDay: task.isAllDay,
    label: '下次',
  );
}

class TaskDetailRecurrenceSection extends ConsumerWidget {
  final Task task;
  final DateTime? activeOccurrenceDate;
  final ValueChanged<DateTime>? onOccurrenceSelected;
  final ValueChanged<bool>? onTimelineScrollLockChanged;

  const TaskDetailRecurrenceSection({
    super.key,
    required this.task,
    this.activeOccurrenceDate,
    this.onOccurrenceSelected,
    this.onTimelineScrollLockChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(taskStreakMapProvider)[task.id];
    final completions = ref.watch(taskCompletionsProvider).valueOrNull ?? [];
    final exceptions =
        ref.watch(taskRecurrenceExceptionsProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final isCapped = task.recurrenceCount != null;

    final Widget? seriesTimeline;
    if (isCapped) {
      const builder = TaskListBuilder();
      final seriesOccs = builder.buildSeriesOccurrences(
        task: task,
        completions: completions,
        exceptions: exceptions,
        now: now,
      );
      seriesTimeline = RecurrenceSeriesTimeline(
        occurrences: seriesOccs,
        selectedOccurrenceDate: activeOccurrenceDate,
        onTapOccurrence: onOccurrenceSelected == null
            ? null
            : (occ) => onOccurrenceSelected!(occ.calendarDay),
        onScrollLockChanged: onTimelineScrollLockChanged,
      );
    } else {
      seriesTimeline = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (streak != null) StreakSummaryCard(info: streak),
          if (seriesTimeline != null) ...[
            const SizedBox(height: 12),
            TempoGlassSurface(
              blur: false,
              fillColor: ref.watch(taskCardBackgroundProvider),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recurrenceSummary(task),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  seriesTimeline,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TaskDetailDescription extends ConsumerWidget {
  final Task task;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSave;

  const TaskDetailDescription({
    super.key,
    required this.task,
    required this.controller,
    required this.isEditing,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cardColor = ref.watch(taskCardBackgroundProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TempoGlassSurface(
                  blur: false,
                  fillColor: cardColor,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '键入备考信息或交互重点说明…',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: t.mono(size: 12, color: t.fgSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onCancelEdit,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onSave,
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: onStartEdit,
              child: TempoGlassSurface(
                blur: false,
                fillColor: cardColor,
                padding: const EdgeInsets.all(14),
                child: Text(
                  task.description?.isNotEmpty == true
                      ? task.description!
                      : '无附加任务描述。点击可输入备注…',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.description?.isNotEmpty == true
                        ? t.fgSecondary
                        : t.fgSubtle,
                    height: 1.5,
                    fontStyle: task.description?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ),
    );
  }
}

class TaskDetailSiyuanCard extends ConsumerWidget {
  final Task task;

  const TaskDetailSiyuanCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cardColor = ref.watch(taskCardBackgroundProvider);
    final blockId = task.siyuanBlockId!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '思源关联卡片',
            style: t.mono(
              size: 10,
              weight: FontWeight.w700,
              color: t.fgMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          TempoGlassSurface(
            blur: false,
            fillColor: cardColor,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.priorityP1Bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    border: Border.all(
                      color: AppTheme.priorityP1Border,
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.link_2,
                    size: 14,
                    color: AppTheme.priorityP1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blockId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '思源笔记块 ID',
                        style: t.mono(size: 9, color: t.fgSubtle),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, size: 14, color: t.fgSubtle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailReadOnlyInfo extends ConsumerWidget {
  final Task task;

  const TaskDetailReadOnlyInfo({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cardColor = ref.watch(taskCardBackgroundProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TempoGlassSurface(
        blur: false,
        fillColor: cardColor,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            TempoPropertyRow(
              icon: LucideIcons.info,
              label: '来源',
              value: Text(
                taskDetailSourceLabel(task.creationSource),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            TempoPropertyRow(
              icon: LucideIcons.circle_dot,
              label: '创建',
              value: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt),
                style: t.mono(size: 12, color: t.fgMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailCompleteButton extends StatelessWidget {
  final Task task;
  final bool isSaving;
  final VoidCallback onPressed;

  const TaskDetailCompleteButton({
    super.key,
    required this.task,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isSaving ? null : onPressed,
          icon: Icon(
            task.isCompleted ? LucideIcons.rotate_ccw : LucideIcons.check,
            size: 14,
          ),
          label: Text(
            task.isCompleted ? '取消完成' : '标记完成',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
