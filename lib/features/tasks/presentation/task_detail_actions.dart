import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_providers.dart';
import '../../../core/extensions/task_filter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';
import 'widgets/quick_create_sheet.dart';

class TaskDetailActions {
  TaskDetailActions({
    required this.ref,
    required this.context,
    required this.onTaskChanged,
    required this.onSavingChanged,
    required this.getTask,
    required this.setLastDeletedTask,
  });

  final WidgetRef ref;
  final BuildContext context;
  final void Function(Task task) onTaskChanged;
  final void Function(bool saving) onSavingChanged;
  final Task? Function() getTask;
  final void Function(Task? task) setLastDeletedTask;

  Future<void> toggleComplete(Task task, {DateTime? occurrenceDate}) async {
    onSavingChanged(true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      final notificationService = ref.read(notificationServiceProvider);

      if (task.isRecurring) {
        // 重复任务按 occurrence 打卡，绝不修改 series 的 is_completed。
        final occDate = occurrenceDate ?? _resolveRecurringOccurrenceDate(task);
        if (occDate == null) {
          onSavingChanged(false);
          return;
        }
        final complete = !task.isCompleted;
        await repository.toggleOccurrenceComplete(
          task.id,
          occDate,
          complete: complete,
        );
        final raw = ref.read(taskMapProvider)[task.id] ?? task;
        await notificationService.scheduleRecurringReminders(
          raw,
          completions: _completionSnapshotAfterToggle(
            task.id,
            occDate,
            complete,
          ),
          exceptions: _exceptionsForTask(task.id),
        );
        if (!context.mounted) return;
        // 详情页本地 state 仍由父 widget 通过 onTaskChanged 反映；
        // 这里仅刷新 saving 状态，列表/连续统计由 stream 推动。
        onSavingChanged(false);
        return;
      }

      final updated = await repository.toggleComplete(task.id);
      if (updated.isCompleted) {
        await notificationService.cancelTaskReminders(task.id);
      } else {
        await notificationService.scheduleTaskReminder(updated);
      }
      if (!context.mounted) return;
      onTaskChanged(updated);
      onSavingChanged(false);
    } catch (e) {
      if (!context.mounted) return;
      onSavingChanged(false);
      TempoSnackbar.show(context, message: '操作失败:$e');
    }
  }

  /// 解析重复任务当前可打卡的 occurrenceDate：优先用 nextCompletableOccurrence，
  /// 兜底到 task.dueDate 当天。
  DateTime? _resolveRecurringOccurrenceDate(Task task) {
    const engine = RecurrenceEngine();
    final completions = ref.read(taskCompletionsProvider).valueOrNull ?? [];
    final exceptions =
        ref.read(taskRecurrenceExceptionsProvider).valueOrNull ?? [];
    final next = engine.nextCompletableOccurrence(
      task,
      completions: completions.forTask(task.id, (c) => c.taskId),
      exceptions: exceptions.forTask(task.id, (e) => e.taskId),
      now: DateTime.now(),
    );
    if (next != null) return next.occurrenceDate;
    return null;
  }

  List<TaskCompletion> _completionSnapshotAfterToggle(
    String taskId,
    DateTime occurrenceDate,
    bool complete,
  ) {
    final day = RecurrenceEngine.calendarDay(occurrenceDate);
    final existing = ref
        .read(taskCompletionsProvider)
        .valueOrNull
        ?.forTask(taskId, (c) => c.taskId);
    final completions = [
      for (final completion in existing ?? const <TaskCompletion>[])
        if (RecurrenceEngine.calendarDay(completion.occurrenceDate) != day)
          completion,
    ];
    if (complete) {
      completions.add(
        TaskCompletion(
          taskId: taskId,
          occurrenceDate: day,
          completedAt: DateTime.now(),
        ),
      );
    }
    return completions;
  }

  List<RecurrenceException> _exceptionsForTask(String taskId) {
    return (ref.read(taskRecurrenceExceptionsProvider).valueOrNull ??
            const <RecurrenceException>[])
        .forTask(taskId, (e) => e.taskId);
  }

  Future<void> saveDescription(String value) async {
    final task = getTask();
    if (task == null) return;
    onSavingChanged(true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = task.copyWith(
        description: value.isEmpty ? null : value,
        updatedAt: DateTime.now(),
      );
      await repository.updateTask(updated);
      if (!context.mounted) return;
      onTaskChanged(updated);
      onSavingChanged(false);
      TempoSnackbar.show(context, message: '描述已保存');
    } catch (e) {
      if (!context.mounted) return;
      onSavingChanged(false);
      TempoSnackbar.show(context, message: '保存失败:$e');
    }
  }

  Future<void> openEditSheet() async {
    final task = getTask();
    if (task == null) return;

    final updatedTask = await QuickCreateSheet.showEdit(
      context,
      task: task,
      onUpdate:
          ({
            required Task task,
            required String title,
            DateTime? dueDate,
            required bool isAllDay,
            TaskPriority priority = TaskPriority.none,
            String? tag,
            String? recurrenceRule,
            DateTime? recurrenceEnd,
            int? recurrenceCount,
            bool clearRecurrenceRule = false,
            bool clearRecurrenceEnd = false,
            bool clearRecurrenceCount = false,
          }) async {
            final repository = ref.read(taskRepositoryProvider);
            final updated = task.copyWith(
              title: title,
              dueDate: dueDate,
              isAllDay: isAllDay,
              priority: priority,
              tag: tag,
              updatedAt: DateTime.now(),
              recurrenceRule: recurrenceRule,
              recurrenceEnd: recurrenceEnd,
              recurrenceCount: recurrenceCount,
              clearRecurrenceRule: clearRecurrenceRule,
              clearRecurrenceEnd: clearRecurrenceEnd,
              clearRecurrenceCount: clearRecurrenceCount,
            );
            final saved = await repository.updateTask(updated);
            final notificationService = ref.read(notificationServiceProvider);
            if (saved.isCompleted) {
              await notificationService.cancelTaskReminders(saved.id);
            } else {
              await notificationService.scheduleTaskReminder(saved);
            }
            return saved;
          },
    );

    if (!context.mounted || updatedTask == null) return;
    onTaskChanged(updatedTask);
    TempoSnackbar.show(context, message: '任务已更新');
  }

  Future<void> showMoreMenu() async {
    final task = getTask();
    if (task == null) return;
    final existingBackground = await ref
        .read(taskBackgroundRepositoryProvider)
        .getBackground(task.id);
    if (!context.mounted) return;
    final hasBackground = existingBackground != null;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.tokens.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('更换背景'),
              onTap: () => Navigator.of(context).pop('background'),
            ),
            if (hasBackground)
              ListTile(
                leading: const Icon(LucideIcons.ban),
                title: const Text('清除背景'),
                onTap: () => Navigator.of(context).pop('clear_background'),
              ),
            if (task.isRecurring && !task.isRecurrenceEnded(DateTime.now()))
              ListTile(
                leading: const Icon(LucideIcons.calendar_x),
                title: const Text('结束重复'),
                onTap: () => Navigator.of(context).pop('end_recurrence'),
              ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash_2,
                color: AppTheme.errorColor,
              ),
              title: const Text(
                '删除待办',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'background':
        await changeBackground(task);
      case 'clear_background':
        await clearBackground(task);
      case 'end_recurrence':
        await confirmEndRecurrence(task);
      case 'delete':
        await confirmDelete(task);
    }
  }

  Future<void> confirmEndRecurrence(Task task) async {
    final confirmed = await TempoConfirmDialog.show(
      context,
      title: '结束重复',
      message: '「${task.title}」将不再重复出现。历史打卡记录会保留。',
      confirmLabel: '结束重复',
    );

    if (confirmed != true || !context.mounted) return;

    onSavingChanged(true);
    try {
      final truncated = ref
          .read(recurrenceRepositoryProvider)
          .truncateSeriesAt(task, DateTime.now());
      final saved = await ref
          .read(taskRepositoryProvider)
          .updateTask(truncated);
      if (!context.mounted) return;
      onTaskChanged(saved);
      onSavingChanged(false);
      TempoSnackbar.show(context, message: '重复已结束');
    } catch (e) {
      if (!context.mounted) return;
      onSavingChanged(false);
      TempoSnackbar.show(context, message: '操作失败: $e');
    }
  }

  Future<void> changeBackground(Task task) async {
    try {
      final background = await ref
          .read(taskBackgroundRepositoryProvider)
          .pickBackgroundImage(task.id);
      if (!context.mounted || background == null) return;
      TempoSnackbar.show(context, message: '背景已更新');
    } catch (e) {
      if (!context.mounted) return;
      TempoSnackbar.show(context, message: '背景更新失败:$e');
    }
  }

  Future<void> clearBackground(Task task) async {
    try {
      await ref.read(taskBackgroundRepositoryProvider).clearBackground(task.id);
      if (!context.mounted) return;
      TempoSnackbar.show(context, message: '背景已清除');
    } catch (e) {
      if (!context.mounted) return;
      TempoSnackbar.show(context, message: '背景清除失败:$e');
    }
  }

  Future<void> confirmDelete(Task task) async {
    final confirmed = await TempoConfirmDialog.show(
      context,
      title: '删除待办',
      message: '确定删除「${task.title}」吗？此操作不可撤销。',
      confirmLabel: '删除',
      isDestructive: true,
    );

    if (confirmed == true) {
      await deleteTask(task);
    }
  }

  Future<void> deleteTask(Task task) async {
    setLastDeletedTask(task);
    final navigatorKey = ref.read(appNavigatorKeyProvider);
    try {
      await ref
          .read(taskBackgroundRepositoryProvider)
          .clearBackground(task.id)
          .catchError((_) {});
      await ref.read(taskRepositoryProvider).deleteTask(task.id);
      if (!context.mounted) return;
      context.pop();
      unawaited(
        ref.read(notificationServiceProvider).cancelTaskReminders(task.id),
      );
      TempoSnackbar.showGlobal(
        navigatorKey: navigatorKey,
        message: '已删除:${task.title}',
        undoLabel: '撤回',
        onUndo: () async {
          final restored = await ref
              .read(taskRepositoryProvider)
              .createTask(
                title: task.title,
                description: task.description,
                dueDate: task.dueDate,
                priority: task.priority,
                creationSource: task.creationSource,
                tag: task.tag,
              );
          await ref
              .read(notificationServiceProvider)
              .scheduleTaskReminder(restored);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      TempoSnackbar.show(context, message: '删除失败:$e');
    }
  }
}
