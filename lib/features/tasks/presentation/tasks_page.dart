// ============================================================
// TasksPage — 任务列表页(Stripe 派 1:1 还原 prototype TasksView.tsx)
// 顶部 StatusBar + H1 + 紧凑范围过滤 + 列表
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
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/recurrence_engine.dart';
import '../domain/task.dart';
import '../domain/task_list_builder.dart';
import '../data/task_creation_orchestrator.dart';
import 'widgets/quick_create_sheet.dart';
import 'widgets/task_tile.dart';
import 'widgets/voice_hold_fab.dart';
import 'widgets/voice_overlay.dart';

enum _TaskScope { pending, overdue, week, all }

enum _VoiceCaptureState { inactive, recording, processing }

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with AutomaticKeepAliveClientMixin {
  _VoiceCaptureState _voiceCapture = _VoiceCaptureState.inactive;
  bool _slideCancel = false;
  String _voiceTranscript = '';
  String? _voiceError;
  VoicePipelinePhase? _pipelinePhase;
  StreamSubscription<String>? _transcriptSub;
  bool _showQuickCreate = false;
  Task? _lastDeletedTask;

  _TaskScope _scope = _TaskScope.pending;
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
    _transcriptSub?.cancel();
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
                        child: _TaskScopeSection(
                          scope: _scope,
                          searchQuery: _debouncedSearchQuery,
                          onScopeChanged: (scope) =>
                              setState(() => _scope = scope),
                        ),
                      ),
                      _TaskListSection(
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
          // 浮动按钮（语音/快速创建 overlay 打开时隐藏）
          if (_voiceCapture == _VoiceCaptureState.inactive && !_showQuickCreate)
            Positioned(
              right: 20,
              bottom: 120,
              child: RepaintBoundary(
                child: VoiceHoldFabColumn(
                  onHoldStart: _beginVoiceCapture,
                  onHoldMove: _updateSlideCancel,
                  onHoldEnd: _endVoiceCapture,
                  onAdd: _openQuickCreate,
                ),
              ),
            ),
          if (_voiceCapture != _VoiceCaptureState.inactive)
            VoiceCaptureOverlay(
              phase: _voiceCapture == _VoiceCaptureState.recording
                  ? VoiceCapturePhase.recording
                  : VoiceCapturePhase.processing,
              slideCancelActive: _slideCancel,
              pipelinePhase: _pipelinePhase,
              transcript: _voiceTranscript,
              error: _voiceError,
            ),
        ],
      ),
    );
  }

  // ══════════════ 语音长按 ══════════════

  void _beginVoiceCapture() {
    ref.read(shellTabBarVisibleProvider.notifier).state = false;
    setState(() {
      _voiceCapture = _VoiceCaptureState.recording;
      _slideCancel = false;
      _voiceTranscript = '';
      _voiceError = null;
      _pipelinePhase = null;
    });
    unawaited(_startVoiceRecording());
  }

  Future<void> _startVoiceRecording() async {
    final session = ref.read(streamingVoiceSessionProvider);
    try {
      if (!session.isPrepared) {
        await session.prepare();
      }
      await session.startRecording();
      if (!mounted || _voiceCapture != _VoiceCaptureState.recording) return;

      _transcriptSub?.cancel();
      _transcriptSub = session.transcriptStream.listen((text) {
        if (!mounted) return;
        setState(() => _voiceTranscript = text);
        ref.read(textParseServiceProvider).parseTextDebounced(text);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceError = formatVoiceStartError(e);
        _voiceCapture = _VoiceCaptureState.inactive;
      });
      ref.read(shellTabBarVisibleProvider.notifier).state = true;
    }
  }

  void _updateSlideCancel(double localDy) {
    final cancel = localDy < -VoiceHoldFabColumn.slideCancelThreshold;
    if (cancel != _slideCancel && mounted) {
      setState(() => _slideCancel = cancel);
    }
  }

  void _endVoiceCapture(bool cancelled) {
    _transcriptSub?.cancel();
    _transcriptSub = null;

    if (cancelled || _voiceCapture != _VoiceCaptureState.recording) {
      unawaited(ref.read(streamingVoiceSessionProvider).cancel());
      _closeVoiceCapture();
      return;
    }

    setState(() {
      _voiceCapture = _VoiceCaptureState.processing;
      _slideCancel = false;
      _pipelinePhase = VoicePipelinePhase.transcribing;
    });

    unawaited(_runVoicePipeline());
  }

  Future<void> _runVoicePipeline() async {
    final session = ref.read(streamingVoiceSessionProvider);
    final orchestrator = ref.read(taskCreationOrchestratorProvider);

    await orchestrator.enqueueVoicePipeline(
      session: session,
      onNeedDraftConfirm: (draft) {
        if (!mounted) return;
        unawaited(QuickCreateSheet.showPrefill(context, draft: draft));
      },
      onPhaseChanged: (phase) {
        if (!mounted) return;
        setState(() => _pipelinePhase = phase);
      },
      onComplete: _closeVoiceCapture,
    );
  }

  void _closeVoiceCapture() {
    if (!mounted) return;
    setState(() {
      _voiceCapture = _VoiceCaptureState.inactive;
      _voiceTranscript = '';
      _voiceError = null;
      _pipelinePhase = null;
      _slideCancel = false;
    });
    ref.read(shellTabBarVisibleProvider.notifier).state = true;
    unawaited(ref.read(streamingVoiceSessionProvider).disposeSession());
  }

  // ══════════════ UI 部分 ══════════════

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateText = DateFormat('M 月 d 日 · EEEE', 'zh_CN').format(now);
    final tokens = context.tokens;
    return RepaintBoundary(
      child: Padding(
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
      final raw = ref.read(taskMapProvider)[task.id];
      final notificationService = ref.read(notificationServiceProvider);

      if (raw?.isRecurring == true) {
        final occDate =
            TaskListBuilder.occurrenceContext[task.id] ??
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

class _TaskListGroups {
  final List<Task> active;
  final List<Task> completed;

  const _TaskListGroups({required this.active, required this.completed});
}

class _TaskScopeCounts {
  final int pending;
  final int overdue;
  final int week;
  final int all;

  const _TaskScopeCounts({
    required this.pending,
    required this.overdue,
    required this.week,
    required this.all,
  });
}

class _TaskFilterSnapshot {
  final _TaskScopeCounts scopeCounts;
  final _TaskListGroups groups;

  const _TaskFilterSnapshot({required this.scopeCounts, required this.groups});
}

/// filter family 的 key：scope / search 二元组。
/// enum + String 都有值语义，record 自动获得 == / hashCode。
typedef _FilterKey = ({_TaskScope scope, String search});

/// 派生 provider：把过滤和计数从 build 内重算提到 provider 层。
/// 仅在 taskListProvider 数据或 filter 输入变化时重算，避免无关 rebuild 重算。
final _taskFilterSnapshotProvider =
    Provider.family<_TaskFilterSnapshot, _FilterKey>((ref, key) {
      final allTasks = ref.watch(displayTaskListProvider);
      return _buildTaskFilterSnapshot(
        allTasks: allTasks,
        scope: key.scope,
        searchQuery: key.search,
      );
    });

_TaskFilterSnapshot _buildTaskFilterSnapshot({
  required List<Task> allTasks,
  required _TaskScope scope,
  required String searchQuery,
}) {
  final searched = <Task>[];
  final active = <Task>[];
  final completed = <Task>[];
  final now = DateTime.now();
  final q = searchQuery.trim().toLowerCase();

  for (final task in allTasks) {
    if (!_matchesSearch(task, q)) {
      continue;
    }
    searched.add(task);

    if (!_matchesScope(task, scope, now)) continue;

    if (task.isCompleted) {
      completed.add(task);
    } else {
      active.add(task);
    }
  }

  return _TaskFilterSnapshot(
    scopeCounts: _countScopes(searched, now),
    groups: _TaskListGroups(active: active, completed: completed),
  );
}

bool _matchesSearch(Task task, String q) {
  if (q.isEmpty) return true;
  return task.title.toLowerCase().contains(q) ||
      (task.description?.toLowerCase().contains(q) ?? false);
}

bool _matchesScope(Task task, _TaskScope scope, DateTime now) {
  final due = task.dueDate;
  return switch (scope) {
    _TaskScope.pending => !task.isCompleted,
    _TaskScope.overdue =>
      due != null &&
          isTaskOverdue(
            dueDate: due,
            isAllDay: task.isAllDay,
            isCompleted: task.isCompleted,
            now: now,
          ),
    _TaskScope.week =>
      !task.isCompleted && due != null && isDueInWeekRange(due, now),
    _TaskScope.all => true,
  };
}

_TaskScopeCounts _countScopes(List<Task> tasks, DateTime now) {
  var pending = 0;
  var overdue = 0;
  var week = 0;
  for (final task in tasks) {
    if (!task.isCompleted) pending++;
    final due = task.dueDate;
    if (due != null &&
        isTaskOverdue(
          dueDate: due,
          isAllDay: task.isAllDay,
          isCompleted: task.isCompleted,
          now: now,
        )) {
      overdue++;
    }
    if (!task.isCompleted && due != null && isDueInWeekRange(due, now)) {
      week++;
    }
  }
  return _TaskScopeCounts(
    pending: pending,
    overdue: overdue,
    week: week,
    all: tasks.length,
  );
}

class _TaskScopeSection extends ConsumerWidget {
  final _TaskScope scope;
  final String searchQuery;
  final ValueChanged<_TaskScope> onScopeChanged;

  const _TaskScopeSection({
    required this.scope,
    required this.searchQuery,
    required this.onScopeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      _taskFilterSnapshotProvider((scope: scope, search: searchQuery)),
    );
    final counts = snapshot.scopeCounts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: TempoGlassSurface(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _FilterPill(
                label: '待处理',
                count: counts.pending,
                selected: scope == _TaskScope.pending,
                onTap: () => onScopeChanged(_TaskScope.pending),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FilterPill(
                label: '逾期',
                count: counts.overdue,
                selected: scope == _TaskScope.overdue,
                tone: counts.overdue > 0
                    ? _FilterPillTone.danger
                    : _FilterPillTone.neutral,
                onTap: () => onScopeChanged(_TaskScope.overdue),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FilterPill(
                label: '本周',
                count: counts.week,
                selected: scope == _TaskScope.week,
                onTap: () => onScopeChanged(_TaskScope.week),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FilterPill(
                label: '全部',
                count: counts.all,
                selected: scope == _TaskScope.all,
                onTap: () => onScopeChanged(_TaskScope.all),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FilterPillTone { neutral, danger }

class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final _FilterPillTone tone;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.tone = _FilterPillTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final danger = tone == _FilterPillTone.danger;
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

class _TaskListSection extends ConsumerWidget {
  final _TaskScope scope;
  final String searchQuery;
  final void Function(Task) onTap;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  const _TaskListSection({
    required this.scope,
    required this.searchQuery,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // filter 重算移入 _taskFilterSnapshotProvider，build 内不再遍历全量任务。
    final snapshot = ref.watch(
      _taskFilterSnapshotProvider((scope: scope, search: searchQuery)),
    );
    final groups = snapshot.groups;
    final async = ref.watch(taskListProvider);
    final backgrounds = ref.watch(taskBackgroundMapProvider);
    final aiEnhancementState = ref.watch(taskAiEnhancementStateProvider);
    final streakMap = ref.watch(taskStreakMapProvider);
    final taskMap = ref.watch(taskMapProvider);

    // 首帧 loading：taskListProvider 尚无数据时显示加载态。
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
                    showRecurring: raw?.isRecurring ?? false,
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
