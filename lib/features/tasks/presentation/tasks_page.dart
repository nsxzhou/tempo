// ============================================================
// TasksPage — 任务列表页 shell
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/task_filter.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../data/notification_service.dart';
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';
import 'tasks_filter.dart';
import 'tasks_voice_handler.dart';
import 'widgets/create_action_fan_fab.dart';
import 'widgets/quick_create_sheet.dart';
import 'widgets/tasks_header.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with AutomaticKeepAliveClientMixin, TasksPageVoiceMixin {
  bool _showQuickCreate = false;
  Task? _lastDeletedTask;

  TaskScope _scope = TaskScope.pending;
  bool _showSearch = false;
  String _debouncedSearchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(streamingVoiceSessionProvider).prepare());
      unawaited(ref.read(streamingVoiceSessionProvider).ensureMicPermission());
      unawaited(_maybeExplainNotificationPermission());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    disposeVoiceMixin();
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
    final tasks = ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
    final capability = ref.watch(notificationCapabilityProvider).valueOrNull;
    final diagnostics = ref.watch(reminderDiagnosticsProvider).valueOrNull;
    final hasScheduledTasks = tasks.any(
      (task) => !task.isCompleted && task.dueDate != null,
    );
    final diagnosticsNeedsAttention =
        diagnostics?.lastResult?.needsAttention == true ||
        (hasScheduledTasks &&
            diagnostics != null &&
            diagnostics.pendingCount == 0);
    final showNotificationWarning =
        hasScheduledTasks &&
        ((capability != null && !capability.isFullyAvailable) ||
            diagnosticsNeedsAttention);

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
                  child: RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: TasksPageHeader(
                            showSearch: _showSearch,
                            onSearchToggle: () =>
                                setState(() => _showSearch = !_showSearch),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: TasksSearchBar(
                            visible: _showSearch,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        if (showNotificationWarning)
                          SliverToBoxAdapter(
                            child: _NotificationPermissionBanner(
                              exactAlarmOnly:
                                  capability?.notificationsAllowed == true &&
                                  capability?.channelEnabled == true &&
                                  capability?.exactAlarmsAllowed == false,
                              message:
                                  diagnosticsNeedsAttention &&
                                      capability?.isFullyAvailable == true
                                  ? '提醒排程异常，点击查看诊断'
                                  : null,
                              onTap: () {
                                if (capability != null &&
                                    !capability.isFullyAvailable) {
                                  _openNotificationSettings(capability);
                                } else {
                                  _showReminderDiagnostics();
                                }
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: TaskScopeSection(
                            scope: _scope,
                            searchQuery: _debouncedSearchQuery,
                            onScopeChanged: (scope) =>
                                setState(() => _scope = scope),
                          ),
                        ),
                        TaskListSection(
                          scope: _scope,
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
          ),
          if (voiceCapture == VoiceCaptureState.inactive && !_showQuickCreate)
            Positioned(
              right: 20,
              bottom: 120 + MediaQuery.paddingOf(context).bottom,
              child: RepaintBoundary(
                child: CreateActionFanFab(
                  onTextCreate: _openQuickCreate,
                  onVoiceInput: armVoiceCapture,
                ),
              ),
            ),
          if (voiceCapture != VoiceCaptureState.inactive)
            Positioned.fill(child: buildVoiceOverlay()!),
        ],
      ),
    );
  }

  Future<void> _maybeExplainNotificationPermission() async {
    final service = ref.read(notificationServiceProvider);
    final capability = await service.capability();
    if (capability.notificationsAllowed || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.prefNotificationPermissionExplained) ==
        true) {
      return;
    }
    await prefs.setBool(AppConstants.prefNotificationPermissionExplained, true);
    if (!mounted) return;
    final accepted = await TempoConfirmDialog.show(
      context,
      title: '开启待办提醒',
      message: '允许 Tempo 发送通知后，即使返回桌面、锁屏或划掉 App，已安排的待办仍可按时提醒。',
      confirmLabel: '开启提醒',
      cancelLabel: '暂不开启',
      barrierDismissible: false,
    );
    if (accepted == true) {
      await service.requestPermissions();
      ref.invalidate(notificationCapabilityProvider);
    }
  }

  Future<void> _openNotificationSettings(
    NotificationCapability capability,
  ) async {
    final service = ref.read(notificationServiceProvider);
    if (!capability.notificationsAllowed) {
      await service.openNotificationSettings();
    } else {
      await service.openExactAlarmSettings();
    }
  }

  Future<void> _showReminderDiagnostics() async {
    final service = ref.read(notificationServiceProvider);
    ReminderDiagnostics diagnostics;
    try {
      diagnostics = await service.diagnostics();
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '读取提醒诊断失败:$error');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('提醒诊断'),
        content: Text(
          [
            '本地时间：${diagnostics.now}',
            '时区：${diagnostics.timezoneName}',
            "通知权限：${diagnostics.capability.notificationsAllowed ? '正常' : '未开启'}",
            "通知渠道：${diagnostics.capability.channelEnabled ? '正常' : '已关闭'}",
            "精确闹钟：${diagnostics.capability.exactAlarmsAllowed ? '正常' : '不可用（将降级）'}",
            '待触发提醒：${diagnostics.pendingCount}',
            "最近结果：${diagnostics.lastResult?.status.name ?? '暂无'}",
            "错误：${diagnostics.lastResult?.error ?? '无'}",
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await service.showTestNotification();
                if (dialogContext.mounted) {
                  TempoSnackbar.show(dialogContext, message: '已发送立即测试通知');
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  TempoSnackbar.show(dialogContext, message: '测试通知失败:$error');
                }
              }
            },
            child: const Text('立即测试'),
          ),
          TextButton(
            onPressed: () async {
              final result = await service.scheduleTestReminder();
              ref.invalidate(reminderDiagnosticsProvider);
              if (dialogContext.mounted) {
                TempoSnackbar.show(
                  dialogContext,
                  message: result.isSuccess
                      ? '两分钟测试提醒已排程'
                      : '测试排程失败:${result.status.name}',
                );
              }
            },
            child: const Text('两分钟测试'),
          ),
          TextButton(
            onPressed: service.openBackgroundSettings,
            child: const Text('后台权限'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    ref.invalidate(reminderDiagnosticsProvider);
  }

  Future<void> _refreshTasks() async {
    try {
      await ref.read(syncServiceProvider).refreshNow();
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '刷新失败:$error');
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final raw = ref.read(taskMapProvider)[task.id];
      final notificationService = ref.read(notificationServiceProvider);

      if (raw?.isRecurring == true) {
        TaskOccurrenceView? view;
        for (final entry in ref.read(displayOccurrenceListProvider)) {
          if (entry.displayTask.id == task.id) {
            view = entry;
            break;
          }
        }
        // 优先用 view 的 occurrence；找不到时退到 nextCompletableOccurrence；
        // 最后兜底到 series dueDate 当天（仅用于取消完成场景）。
        DateTime? occDate = view?.occurrence.occurrenceDate;
        if (occDate == null) {
          const engine = RecurrenceEngine();
          final completions =
              ref.read(taskCompletionsProvider).valueOrNull ?? [];
          final exceptions =
              ref.read(taskRecurrenceExceptionsProvider).valueOrNull ?? [];
          occDate = engine
              .nextCompletableOccurrence(
                raw!,
                completions: completions.forTask(raw.id, (c) => c.taskId),
                exceptions: exceptions.forTask(raw.id, (e) => e.taskId),
                now: DateTime.now(),
              )
              ?.occurrenceDate;
        }
        if (occDate == null) {
          // 已结束或无下次 occurrence，但仍可能是已完成态需取消。
          if (!task.isCompleted) return;
          occDate = raw!.dueDate != null
              ? RecurrenceEngine.calendarDay(raw.dueDate!)
              : RecurrenceEngine.calendarDay(DateTime.now());
        }
        final complete = !task.isCompleted;
        await repository.toggleOccurrenceComplete(
          task.id,
          occDate,
          complete: complete,
        );
        unawaited(
          notificationService.scheduleRecurringReminders(
            raw!,
            completions: _completionSnapshotAfterToggle(
              task.id,
              occDate,
              complete,
            ),
            exceptions: _exceptionsForTask(task.id),
          ),
        );
      } else {
        final updated = await repository.toggleComplete(task.id);
        if (updated.isCompleted) {
          unawaited(notificationService.cancelTaskReminders(task.id));
        } else {
          unawaited(notificationService.scheduleTaskReminder(updated));
        }
      }
    } catch (error) {
      if (!mounted) return;
      TempoSnackbar.show(context, message: '操作失败:$error');
    }
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

  void _navigateToDetail(Task task) {
    ref.read(taskDetailOverlayProvider.notifier).state = true;
    context.push('/tasks/${task.id}').whenComplete(() {
      ref.read(taskDetailOverlayProvider.notifier).state = false;
    });
  }

  Future<void> _deleteTask(Task task) async {
    _lastDeletedTask = task;
    try {
      await ref
          .read(taskBackgroundRepositoryProvider)
          .clearBackground(task.id)
          .catchError((_) {});
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

class _NotificationPermissionBanner extends StatelessWidget {
  const _NotificationPermissionBanner({
    required this.exactAlarmOnly,
    required this.onTap,
    this.message,
  });

  final bool exactAlarmOnly;
  final VoidCallback onTap;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        key: const ValueKey('notification-permission-banner'),
        color: tokens.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.borderStrong),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  exactAlarmOnly
                      ? LucideIcons.clock_alert
                      : LucideIcons.bell_off,
                  size: 16,
                  color: tokens.fg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ??
                        (exactAlarmOnly
                            ? '精确提醒未开启，点击前往系统设置'
                            : '通知权限或渠道未开启，待办可能无法提醒'),
                    style: TextStyle(
                      color: tokens.fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevron_right,
                  size: 15,
                  color: tokens.fgMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
