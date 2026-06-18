// ============================================================
// TaskDetailPage — 任务详情编辑页
// 编辑标题/描述/优先级/截止时间 + 删除按钮（带二次确认）
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/task.dart';

/// 任务详情编辑页。
///
/// 可编辑标题、描述、优先级、截止时间。
/// 右上角删除按钮带二次确认 Dialog。
class TaskDetailPage extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Task? _task;
  TaskPriority _selectedPriority = TaskPriority.none;
  DateTime? _selectedDueDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    final repository = ref.read(taskRepositoryProvider);
    final task = await repository.getTaskById(widget.taskId);

    if (!mounted) return;

    if (task == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务不存在')),
      );
      context.pop();
      return;
    }

    setState(() {
      _task = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority;
      _selectedDueDate = task.dueDate;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: '删除任务',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text('标题', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '输入任务标题',
              ),
            ),
            const SizedBox(height: 24),

            // 描述
            Text('描述', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '添加描述（可选）',
              ),
            ),
            const SizedBox(height: 24),

            // 优先级
            Text('优先级', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: TaskPriority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      if (p != TaskPriority.none)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.priorityColor(p.value),
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(width: 12),
                      const SizedBox(width: 8),
                      Text(p.label ?? '无'),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // 截止时间
            Text('截止时间', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _selectedDueDate != null
                      ? DateFormat('yyyy年M月d日 HH:mm').format(_selectedDueDate!)
                      : '未设置',
                  style: TextStyle(
                    color: _selectedDueDate != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            if (_selectedDueDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _selectedDueDate = null),
                  child: const Text('清除截止时间'),
                ),
              ),
            const SizedBox(height: 24),

            // 只读信息
            if (_task != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _ReadOnlyInfo(
                label: '创建来源',
                value: _sourceLabel(_task!.creationSource),
              ),
              const SizedBox(height: 8),
              _ReadOnlyInfo(
                label: '创建时间',
                value: DateFormat('yyyy-MM-dd HH:mm').format(_task!.createdAt),
              ),
              if (_task!.siyuanBlockId != null) ...[
                const SizedBox(height: 8),
                _ReadOnlyInfo(
                  label: '思源关联',
                  value: '已关联',
                ),
              ],
            ],

            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveTask,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择截止日期和时间。
  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? pickedDate),
    );

    if (!mounted) return;

    setState(() {
      if (pickedTime != null) {
        _selectedDueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      } else {
        _selectedDueDate = pickedDate;
      }
    });
  }

  /// 保存修改。
  Future<void> _saveTask() async {
    if (_task == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题不能为空')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = _task!.copyWith(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        updatedAt: DateTime.now(),
      );

      await repository.updateTask(updated);

      // 重新调度通知
      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        await notificationService.cancelTaskReminders(updated.id);
      } else {
        await notificationService.scheduleTaskReminder(updated);
      }

      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 确认删除任务。
  Future<void> _confirmDelete() async {
    if (_task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除「${_task!.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.deleteTask(_task!.id);

      // 取消通知
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelTaskReminders(_task!.id);

      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error')),
      );
    }
  }

  String _sourceLabel(String source) {
    return switch (source) {
      AppConstants.sourceVoice => '语音 🎤',
      AppConstants.sourceSiyuan => '思源笔记',
      AppConstants.sourceAi => 'AI 排期',
      _ => '文本输入',
    };
  }
}

/// 只读信息行。
class _ReadOnlyInfo extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
