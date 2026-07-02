import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/recurrence_models.dart';

/// 有次数上限的重复系列时间轴（横向胶囊）。
///
/// 每个 occurrence 一枚 chip：日期 + 状态图标。完成态高对比强调，
/// 其余保持黑白灰克制风格。
class RecurrenceSeriesTimeline extends StatelessWidget {
  const RecurrenceSeriesTimeline({
    super.key,
    required this.occurrences,
    this.selectedOccurrenceDate,
    this.onTapOccurrence,
    this.onScrollLockChanged,
  });

  final List<TaskOccurrence> occurrences;
  final DateTime? selectedOccurrenceDate;
  final void Function(TaskOccurrence occurrence)? onTapOccurrence;
  final ValueChanged<bool>? onScrollLockChanged;

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    final today = calendarDay(DateTime.now());
    final selectedDay = selectedOccurrenceDate != null
        ? calendarDay(selectedOccurrenceDate!)
        : null;
    final completed = occurrences
        .where((o) => o.state == OccurrenceState.completed)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '打卡进度',
              style: tokens.mono(size: 11, color: tokens.fgMuted),
            ),
            Text(
              '已完成 $completed / ${occurrences.length} 次',
              style: tokens.mono(
                size: 11,
                color: tokens.fgMuted,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 68,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (onScrollLockChanged == null) return false;
              if (notification.metrics.axis != Axis.horizontal) return false;
              if (notification is ScrollStartNotification) {
                onScrollLockChanged!(true);
              } else if (notification is ScrollEndNotification) {
                onScrollLockChanged!(false);
              }
              return false;
            },
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              itemCount: occurrences.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final occ = occurrences[index];
                return _OccurrenceChip(
                  occurrence: occ,
                  index: index + 1,
                  isToday: occ.calendarDay == today,
                  isSelected:
                      selectedDay != null && occ.calendarDay == selectedDay,
                  tokens: tokens,
                  onTap: onTapOccurrence == null
                      ? null
                      : () => onTapOccurrence!(occ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OccurrenceChip extends StatelessWidget {
  const _OccurrenceChip({
    required this.occurrence,
    required this.index,
    required this.isToday,
    required this.isSelected,
    required this.tokens,
    this.onTap,
  });

  final TaskOccurrence occurrence;
  final int index;
  final bool isToday;
  final bool isSelected;
  final TempoTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = occurrence.calendarDay;
    final dateLabel = '${date.month}/${date.day}';

    final (Color bg, Color border, Color fg, IconData icon) = switch (
      occurrence.state
    ) {
      OccurrenceState.completed => (
        tokens.success,
        tokens.success,
        Colors.white,
        LucideIcons.check,
      ),
      OccurrenceState.missed => (
        tokens.bgMuted,
        tokens.borderStrong,
        tokens.fgFaint,
        LucideIcons.x,
      ),
      OccurrenceState.pending => (
        tokens.bg,
        isToday ? tokens.fg : tokens.borderStrong,
        tokens.fgMuted,
        LucideIcons.circle,
      ),
    };

    final borderWidth = isSelected
        ? 2.0
        : (isToday && occurrence.state == OccurrenceState.pending ? 1.4 : 0.8);
    final borderColor = isSelected ? tokens.fg : border;

    final chip = Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '第$index次',
            style: tokens.mono(
              size: 9,
              color: occurrence.state == OccurrenceState.completed
                  ? Colors.white.withValues(alpha: 0.85)
                  : tokens.fgFaint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Icon(icon, size: 12, color: fg),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: chip,
      ),
    );
  }
}
