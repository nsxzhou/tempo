// ============================================================
// TasksPage — 任务列表页 shell
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_providers.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/widgets/tempo/tempo.dart';
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
        final occDate =
            view?.occurrence.occurrenceDate ??
            RecurrenceEngine.calendarDay(task.dueDate ?? DateTime.now());
        final complete = !task.isCompleted;
        await repository.toggleOccurrenceComplete(
          task.id,
          occDate,
          complete: complete,
        );
        if (complete) {
          unawaited(
            notificationService.cancelOccurrenceReminder(task.id, occDate),
          );
        } else {
          unawaited(
            notificationService.scheduleRecurringReminders(
              raw!,
              completions: const [],
              exceptions: const [],
            ),
          );
        }
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
