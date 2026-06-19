// ============================================================
// TaskDetailPage — 任务详情页
// 顶部 sticky 返回 + 编辑/更多按钮
// 优先级 / tag / 来源徽章 + H1 衬线斜体 32px
// TempoPropertyRow(截止/归属)
// 可点击编辑描述
// 思源关联卡（siyuanBlockId 非空时展示）
// 底部"标记完成"按钮
// 业务逻辑(Repository + 通知)保留
// TODO: 子任务应在 Task 模型扩展后接入
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/task.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  Task? _task;
  String? _listName;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingDesc = false;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _loadTask();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    final repository = ref.read(taskRepositoryProvider);
    final db = ref.read(databaseProvider);
    final task = await repository.getTaskById(widget.taskId);
    if (!mounted) return;
    if (task == null) {
      setState(() => _isLoading = false);
      TempoSnackbar.show(context, message: '任务不存在');
      context.pop();
      return;
    }
    final taskList = await db.getTaskListById(task.listId);
    if (!mounted) return;
    setState(() {
      _task = task;
      _listName = _resolveListName(task.listId, taskList?.name);
      _descController.text = task.description ?? '';
      _isLoading = false;
    });
  }

  String _resolveListName(String listId, String? dbName) {
    if (dbName != null && dbName.isNotEmpty) return dbName;
    if (listId == 'local-inbox') return AppConstants.defaultListName;
    return listId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task!;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _TopBar(onBack: () => context.pop()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleBlock(task),
                  const SizedBox(height: 16),
                  _buildProperties(task),
                  const SizedBox(height: 16),
                  _buildDescription(task),
                  if (task.siyuanBlockId != null) ...[
                    const SizedBox(height: 16),
                    _buildSiyuanCard(task),
                  ],
                  const SizedBox(height: 16),
                  _buildReadOnlyInfo(task),
                  const SizedBox(height: 24),
                  _buildCompleteButton(task),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════ UI 部分 ══════════════

  Widget _buildTitleBlock(Task task) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
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
                TempoPillBadge(
                  label: '@工作',
                  kind: TempoBadgeKind.tag,
                  uppercase: false,
                  fontSize: 10,
                )
              else if (task.tag == AppConstants.tagLife)
                TempoPillBadge(
                  label: '@生活',
                  kind: TempoBadgeKind.tag,
                  uppercase: false,
                  fontSize: 10,
                ),
              if (task.creationSource != 'text')
                TempoPillBadge(
                  label: '#${_sourceTag(task.creationSource)}',
                  kind: TempoBadgeKind.neutral,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: AppTheme.italicSerif(
              size: 32,
              color: AppTheme.fg,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProperties(Task task) {
    final now = DateTime.now();
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(now) &&
        !task.isCompleted;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(
          top: BorderSide(color: AppTheme.borderStrong, width: 0.8),
          bottom: BorderSide(color: AppTheme.borderStrong, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          TempoPropertyRow(
            icon: LucideIcons.calendar,
            label: '截止',
            value: task.dueDate != null
                ? Row(
                    children: [
                      Text(
                        DateFormat('M月d日 HH:mm').format(task.dueDate!),
                        style: AppTheme.mono(
                          size: 13,
                          weight: FontWeight.w500,
                        ),
                      ),
                      if (!task.isCompleted) ...[
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.fgSubtle,
                    ),
                  ),
          ),
          TempoPropertyRow(
            icon: LucideIcons.folder,
            label: '归属',
            value: Text(
              _listName ?? _resolveListName(task.listId, null),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _isEditingDesc
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '键入备考信息或交互重点说明…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.fg, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.fg, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.fg, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _isEditingDesc = false;
                        _descController.text = task.description ?? '';
                      }),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _isEditingDesc = false;
                        });
                        _saveDescription(_descController.text.trim());
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: () => setState(() => _isEditingDesc = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                ),
                child: Text(
                  task.description?.isNotEmpty == true
                      ? task.description!
                      : '无附加任务描述。点击可输入备注…',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.description?.isNotEmpty == true
                        ? AppTheme.fgSecondary
                        : AppTheme.fgSubtle,
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

  Widget _buildSiyuanCard(Task task) {
    final blockId = task.siyuanBlockId!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '思源关联卡片',
            style: AppTheme.mono(
              size: 10,
              weight: FontWeight.w700,
              color: AppTheme.fgMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgSubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderStrong, width: 0.8),
              boxShadow: AppTheme.shadowSm,
            ),
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
                  child: Icon(
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
                        style: AppTheme.mono(
                          size: 9,
                          color: AppTheme.fgSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevron_right,
                  size: 14,
                  color: AppTheme.fgSubtle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfo(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TempoPropertyRow(
            icon: LucideIcons.info,
            label: '来源',
            value: Text(
              _sourceLabel(task.creationSource),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TempoPropertyRow(
            icon: LucideIcons.circle_dot,
            label: '创建',
            value: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt),
              style: AppTheme.mono(
                size: 12,
                color: AppTheme.fgMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : () => _toggleComplete(task),
          icon: Icon(
            task.isCompleted
                ? LucideIcons.rotate_ccw
                : LucideIcons.check,
            size: 14,
          ),
          label: Text(
            task.isCompleted ? '取消完成' : '标记完成',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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

  // ══════════════ 业务逻辑 ══════════════

  Future<void> _toggleComplete(Task task) async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = await repository.toggleComplete(task.id);
      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        await notificationService.cancelTaskReminders(task.id);
      } else {
        await notificationService.scheduleTaskReminder(updated);
      }
      if (!mounted) return;
      setState(() {
        _task = updated;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      TempoSnackbar.show(context, message: '操作失败:$e');
    }
  }

  Future<void> _saveDescription(String value) async {
    final task = _task;
    if (task == null) return;
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = task.copyWith(
        description: value.isEmpty ? null : value,
        updatedAt: DateTime.now(),
      );
      await repository.updateTask(updated);
      if (!mounted) return;
      setState(() {
        _task = updated;
        _isSaving = false;
      });
      TempoSnackbar.show(context, message: '描述已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      TempoSnackbar.show(context, message: '保存失败:$e');
    }
  }

  String _sourceTag(String s) {
    switch (s) {
      case 'voice':
        return '语音';
      case 'siyuan':
        return '思源';
      case 'ai':
        return 'AI';
      default:
        return '文本';
    }
  }

  String _sourceLabel(String s) {
    switch (s) {
      case 'voice':
        return '语音 🎤';
      case 'siyuan':
        return '思源笔记';
      case 'ai':
        return 'AI 排期';
      default:
        return '文本输入';
    }
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(LucideIcons.chevron_left, size: 16),
              label: const Text('返回'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.fgSecondary,
              ),
            ),
            const Spacer(),
            _IconBtn(icon: LucideIcons.pencil, onTap: () {}),
            const SizedBox(width: 6),
            _IconBtn(icon: LucideIcons.ellipsis, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        side: const BorderSide(color: AppTheme.borderStrong, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 14, color: AppTheme.fgSecondary),
        ),
      ),
    );
  }
}
