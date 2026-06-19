// ============================================================
// TaskTile — 任务列表项(Stripe 派 1:1 还原 prototype TasksView.tsx)
// 圆 Checkbox 18px + 34px 命中区 + 优先级 pill + 截止 pill + @tag pill
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../domain/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onTagClick;
  final bool showDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
    this.onTagClick,
    this.showDelete = false,
  });

  String get _deadlineText {
    if (task.dueDate == null) return '未排期';
    final now = DateTime.now();
    final due = task.dueDate!;
    if (task.isCompleted) return '已完成';
    if (due.isBefore(now)) return '已过期';
    if (due.year == now.year && due.month == now.month && due.day == now.day) {
      return '今天 ${_hm(due)}';
    }
    return '${due.month}月${due.day}日 ${_hm(due)}';
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Material(
      color: AppTheme.bg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: task.isCompleted
                  ? AppTheme.borderSubtle
                  : AppTheme.borderStrong,
              width: 0.8,
            ),
            boxShadow: task.isCompleted ? null : AppTheme.shadowSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 34px 命中区包裹 18px 圆 Checkbox
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleComplete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 2),
                  child: TempoCheckbox(
                    value: task.isCompleted,
                    onChanged: (_) => onToggleComplete?.call(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 标题 + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? AppTheme.fgMuted
                            : AppTheme.fg,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (task.priority.value != 0)
                          TempoPillBadge(
                            label: 'P${task.priority.value - 1}',
                            kind: switch (task.priority.value) {
                              1 => TempoBadgeKind.p0,
                              2 => TempoBadgeKind.p1,
                              3 => TempoBadgeKind.p2,
                              _ => TempoBadgeKind.p3,
                            },
                          ),
                        if (isOverdue && !task.isCompleted)
                          TempoPillBadge(
                            label: '已过期',
                            kind: TempoBadgeKind.error,
                            icon: LucideIcons.circle_alert,
                          )
                        else if (task.dueDate != null)
                          TempoPillBadge(
                            label: _deadlineText,
                            kind: TempoBadgeKind.neutral,
                            uppercase: false,
                            fontSize: 10,
                          ),
                        if (task.creationSource == AppConstants.sourceSiyuan)
                          TempoPillBadge(
                            label: '思源',
                            kind: TempoBadgeKind.tag,
                            icon: LucideIcons.link_2,
                          )
                        else if (task.creationSource ==
                            AppConstants.sourceVoice)
                          TempoPillBadge(
                            label: '语音',
                            kind: TempoBadgeKind.tag,
                            icon: LucideIcons.mic,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // 右侧
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.siyuanBlockId != null) ...[
                    const Icon(
                      LucideIcons.link_2,
                      size: 14,
                      color: AppTheme.fgMuted,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (showDelete && onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          LucideIcons.trash_2,
                          size: 14,
                          color: AppTheme.fgMuted,
                        ),
                      ),
                    ),
                  const Icon(
                    LucideIcons.chevron_right,
                    size: 12,
                    color: AppTheme.fgFaint,
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
