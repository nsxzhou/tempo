// ============================================================
// TaskTile — 任务列表项
// 自适应布局：仅标题紧凑居中；有描述显示摘要；有 meta 显示 pills
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
    if (task.dueDate == null) return '';
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

  bool get _hasDescription =>
      task.description != null && task.description!.trim().isNotEmpty;

  List<Widget> _buildMetaPills() {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;
    final pills = <Widget>[];

    if (task.priority.value != 0) {
      pills.add(
        TempoPillBadge(
          label: 'P${task.priority.value - 1}',
          kind: switch (task.priority.value) {
            1 => TempoBadgeKind.p0,
            2 => TempoBadgeKind.p1,
            3 => TempoBadgeKind.p2,
            _ => TempoBadgeKind.p3,
          },
        ),
      );
    }

    if (isOverdue && !task.isCompleted) {
      pills.add(
        TempoPillBadge(
          label: '已过期',
          kind: TempoBadgeKind.error,
          icon: LucideIcons.circle_alert,
        ),
      );
    } else if (task.dueDate != null) {
      pills.add(
        TempoPillBadge(
          label: _deadlineText,
          kind: TempoBadgeKind.neutral,
          uppercase: false,
          fontSize: 10,
        ),
      );
    }

    if (task.tag == AppConstants.tagWork) {
      pills.add(_tagPill('@工作'));
    } else if (task.tag == AppConstants.tagLife) {
      pills.add(_tagPill('@生活'));
    }

    if (task.creationSource == AppConstants.sourceSiyuan) {
      pills.add(
        TempoPillBadge(
          label: '思源',
          kind: TempoBadgeKind.tag,
          icon: LucideIcons.link_2,
        ),
      );
    } else if (task.creationSource == AppConstants.sourceVoice) {
      pills.add(
        TempoPillBadge(
          label: '语音',
          kind: TempoBadgeKind.tag,
          icon: LucideIcons.mic,
        ),
      );
    }

    return pills;
  }

  Widget _tagPill(String label) {
    return GestureDetector(
      onTap: onTagClick,
      child: TempoPillBadge(
        label: label,
        kind: TempoBadgeKind.tag,
        uppercase: false,
        fontSize: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metaPills = _buildMetaPills();
    final hasMeta = metaPills.isNotEmpty;
    final rowAlign = (!_hasDescription && !hasMeta)
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

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
            crossAxisAlignment: rowAlign,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            task.isCompleted ? AppTheme.fgMuted : AppTheme.fg,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    if (_hasDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.fgSubtle,
                          height: 1.35,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                    if (hasMeta) ...[
                      SizedBox(height: _hasDescription ? 6 : 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: metaPills,
                      ),
                    ],
                  ],
                ),
              ),
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
