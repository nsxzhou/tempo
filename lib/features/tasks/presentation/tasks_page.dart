// ============================================================
// TasksPage — 任务列表页(Stripe 派 1:1 还原 prototype TasksView.tsx)
// 顶部 StatusBar + H1 + Bento 4 卡过滤 + 工作/生活 segmented + 列表
// + 浮动 Mic/Plus 双按钮
// 业务逻辑完全保留:语音录音/解析、草稿卡、撤回 Snackbar、Repository
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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

class _TasksPageState extends ConsumerState<TasksPage> {
  bool _showVoiceOverlay = false;
  bool _showQuickCreate = false;
  Task? _lastDeletedTask;

  _TimeFilter _timeFilter = _TimeFilter.today;
  _CategoryFilter _categoryFilter = _CategoryFilter.all;
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // 主滚动区（让原生系统状态栏接管顶部）
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 头部
                    _buildHeader(),
                    // 搜索框(可展开)
                    if (_showSearch) _buildSearchBar(),
                    // Bento 4 卡
                    _buildBentoStats(tasks),
                    // 工作/生活 segmented
                    _buildCategoryFilter(tasks),
                    // 列表
                    tasks.when(
                      data: (items) => _buildTaskList(items),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(child: Text('加载失败:$error')),
                      ),
                    ),
                    // 间距
                    const SizedBox(height: 80),
                  ],
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
    return Padding(
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
                  style: AppTheme.sansSemibold(
                    size: 32,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateText,
                  style: AppTheme.mono(
                    size: 12,
                    color: AppTheme.fgMuted,
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
                color: _showSearch ? AppTheme.bgSubtle : AppTheme.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showSearch
                      ? AppTheme.fg
                      : AppTheme.borderStrong,
                  width: 0.8,
                ),
              ),
              child: Icon(
                LucideIcons.search,
                size: 14,
                color: AppTheme.fgSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(
              LucideIcons.search,
              size: 14,
              color: AppTheme.fgSubtle,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  hintText: '检索日常任务或内容…',
                  hintStyle: AppTheme.mono(
                    size: 12,
                    color: AppTheme.fgSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoStats(AsyncValue<List<Task>> tasks) {
    final data = tasks.valueOrNull ?? [];
    final pending = data.where((t) => !t.isCompleted).length;
    final overdue = data.where((t) {
      return t.dueDate != null &&
          isTaskOverdue(
            dueDate: t.dueDate!,
            isAllDay: t.isAllDay,
            isCompleted: t.isCompleted,
          );
    }).length;
    final now = DateTime.now();
    final weekCount = data
        .where((t) => t.dueDate != null && isDueInWeekRange(t.dueDate!, now))
        .length;
    final total = data.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
            value: '$pending',
            unit: '项未完成',
            selected: _timeFilter == _TimeFilter.today,
            dotColor: AppTheme.priorityP2,
            onTap: () => setState(() => _timeFilter = _TimeFilter.today),
          ),
          _BentoCard(
            label: '已过期',
            value: '$overdue',
            unit: '项超期',
            selected: _timeFilter == _TimeFilter.overdue,
            dotColor: overdue > 0 ? AppTheme.priorityP0 : AppTheme.fgMuted,
            dotPulse: overdue > 0,
            errorTone: overdue > 0,
            onTap: () => setState(() => _timeFilter = _TimeFilter.overdue),
          ),
          _BentoCard(
            label: '本周安排',
            value: '$weekCount',
            unit: '项总代办',
            selected: _timeFilter == _TimeFilter.week,
            dotColor: AppTheme.fgFaint,
            onTap: () => setState(() => _timeFilter = _TimeFilter.week),
          ),
          _BentoCard(
            label: '全部任务',
            value: '$total',
            unit: '项总代办',
            selected: _timeFilter == _TimeFilter.all,
            dotColor: AppTheme.success,
            onTap: () => setState(() => _timeFilter = _TimeFilter.all),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(AsyncValue<List<Task>> tasks) {
    final data = tasks.valueOrNull ?? [];
    final all = data.length;
    final work = data.where((t) => t.tag == AppConstants.tagWork).length;
    final life = data.where((t) => t.tag == AppConstants.tagLife).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SegmentedButton<_CategoryFilter>(
        segments: [
          ButtonSegment(
            value: _CategoryFilter.all,
            label: _segLabel('全部', all),
          ),
          ButtonSegment(
            value: _CategoryFilter.work,
            label: _segLabel('工作', work),
          ),
          ButtonSegment(
            value: _CategoryFilter.life,
            label: _segLabel('生活', life),
          ),
        ],
        selected: {_categoryFilter},
        onSelectionChanged: (s) =>
            setState(() => _categoryFilter = s.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: AppTheme.bgMuted,
          selectedBackgroundColor: AppTheme.bg,
          selectedForegroundColor: AppTheme.fg,
          foregroundColor: AppTheme.fgSecondary,
          side: const BorderSide(color: AppTheme.borderStrong, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
    );
  }

  Widget _segLabel(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.fg.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: AppTheme.mono(
              size: 9,
              weight: FontWeight.w600,
              color: AppTheme.fgMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> allTasks) {
    // 过滤
    var tasks = allTasks;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    final now = DateTime.now();
    // 时间维度过滤
    switch (_timeFilter) {
      case _TimeFilter.today:
        tasks = tasks.where((t) => !t.isCompleted).toList();
        break;
      case _TimeFilter.week:
        tasks = tasks
            .where((t) =>
                t.dueDate != null && isDueInWeekRange(t.dueDate!, now))
            .toList();
        break;
      case _TimeFilter.overdue:
        tasks = tasks
            .where((t) =>
                t.dueDate != null &&
                isTaskOverdue(
                  dueDate: t.dueDate!,
                  isAllDay: t.isAllDay,
                  isCompleted: t.isCompleted,
                  now: now,
                ))
            .toList();
        break;
      case _TimeFilter.all:
        break;
    }
    // 类别维度过滤(与 _buildCategoryFilter 统计口径一致)
    if (_categoryFilter != _CategoryFilter.all) {
      tasks = tasks.where((t) {
        if (_categoryFilter == _CategoryFilter.work) {
          return t.tag == AppConstants.tagWork;
        }
        return t.tag == AppConstants.tagLife;
      }).toList();
    }

    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
        child: Center(
          child: Text(
            '暂无任务',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.fgMuted,
            ),
          ),
        ),
      );
    }

    final active = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) ...[
          TempoSectionHeader(label: '待办 · ${active.length}'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                for (int i = 0; i < active.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  TaskTile(
                    task: active[i],
                    onTap: () => _navigateToDetail(active[i]),
                    onToggleComplete: () => _toggleTask(active[i]),
                    showDelete: true,
                    onDelete: () => _deleteTask(active[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (completed.isNotEmpty) ...[
          TempoSectionHeader(
            label: '已完成 · ${completed.length}',
            color: AppTheme.fgSubtle,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                for (int i = 0; i < completed.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Opacity(
                    opacity: 0.6,
                    child: TaskTile(
                      task: completed[i],
                      onTap: () => _navigateToDetail(completed[i]),
                      onToggleComplete: () => _toggleTask(completed[i]),
                      showDelete: true,
                      onDelete: () => _deleteTask(completed[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════ 业务逻辑(完全保留) ══════════════

  Future<void> _toggleTask(Task task) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = await repository.toggleComplete(task.id);
      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        await notificationService.cancelTaskReminders(task.id);
      } else {
        await notificationService.scheduleTaskReminder(updated);
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
      await ref
          .read(notificationServiceProvider)
          .cancelTaskReminders(task.id);
      if (!mounted) return;
      TempoSnackbar.show(
        context,
        message: '已删除:${task.title}',
        undoLabel: '撤回',
        onUndo: () async {
          if (_lastDeletedTask != null) {
            await ref.read(taskRepositoryProvider).createTask(
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

// ══════════════ 子组件 ══════════════

class _BentoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bg = selected
        ? (errorTone ? const Color(0xFF450A0A) : AppTheme.fg)
        : (errorTone ? const Color(0xFFFEF2F2) : AppTheme.bg);
    final fg = selected
        ? (errorTone ? const Color(0xFFFEE2E2) : AppTheme.bg)
        : (errorTone ? const Color(0xFFB91C1C) : AppTheme.fg);
    final subtle = selected
        ? (errorTone ? const Color(0xFFFCA5A5) : AppTheme.fgMuted)
        : AppTheme.fgMuted;
    final border = selected
        ? bg
        : (errorTone ? const Color(0xFFFECACA) : AppTheme.borderStrong);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: border, width: 0.8),
            boxShadow: selected ? null : AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTheme.mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: subtle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
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
                      unit,
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
        _Fab(
          icon: LucideIcons.plus,
          onTap: onAdd,
          filled: true,
        ),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _Fab({super.key, required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppTheme.fg : AppTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: filled ? AppTheme.fg : AppTheme.borderStrong,
          width: 0.8,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 22,
            color: filled ? AppTheme.bg : AppTheme.fg,
          ),
        ),
      ),
    );
  }
}
