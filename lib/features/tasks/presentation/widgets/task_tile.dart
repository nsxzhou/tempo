// ============================================================
// TaskTile — 可复用任务列表项
// Checkbox + 优先级色 + 标题 + 截止日期 + 左滑删除
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';

/// 可复用任务列表项 Widget。
///
/// 显示 Checkbox + 优先级色标 + 标题 + 截止日期。
/// 支持左滑删除、点击进入详情。
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.priorityColor(task.priority.value);
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggleComplete?.call(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Row(
            children: [
              // 优先级色标
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
              ),
              if (task.creationSource == AppConstants.sourceVoice)
                Icon(Icons.mic, size: 16, color: Colors.grey.shade400)
              else if (task.creationSource == AppConstants.sourceSiyuan)
                Icon(Icons.description, size: 16, color: Colors.grey.shade400),
            ],
          ),
          subtitle: _buildSubtitle(isOverdue),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(bool isOverdue) {
    final parts = <InlineSpan>[];

    if (task.dueDate != null) {
      final dateText = DateFormat('M月d日 HH:mm').format(task.dueDate!);
      parts.add(TextSpan(
        text: dateText,
        style: TextStyle(
          fontSize: 13,
          color: isOverdue ? AppTheme.errorColor : Colors.grey.shade600,
          fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
        ),
      ));
    }

    if (task.priority != TaskPriority.none) {
      if (parts.isNotEmpty) {
        parts.add(const TextSpan(text: ' · '));
      }
      parts.add(TextSpan(
        text: task.priority.label ?? '',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.priorityColor(task.priority.value),
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    if (task.description?.isNotEmpty == true) {
      if (parts.isNotEmpty) {
        parts.add(const TextSpan(text: ' · '));
      }
      parts.add(TextSpan(
        text: task.description!,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade500,
        ),
      ));
    }

    if (parts.isEmpty) return null;

    return RichText(text: TextSpan(children: parts));
  }
}
