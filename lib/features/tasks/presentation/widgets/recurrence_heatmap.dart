import 'package:flutter/material.dart';

import '../../domain/recurrence_models.dart';
import '../../domain/task.dart';

/// 近 12 周打卡热力图
class RecurrenceHeatmap extends StatelessWidget {
  const RecurrenceHeatmap({
    super.key,
    required this.task,
    required this.dayStates,
  });

  final Task task;
  final Map<DateTime, OccurrenceState> dayStates;

  @override
  Widget build(BuildContext context) {
    if (!task.isRecurring) return const SizedBox.shrink();

    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 7 * 12));
    final cells = <Widget>[];

    for (var i = 0; i < 12 * 7; i++) {
      final day = DateTime(
        start.year,
        start.month,
        start.day,
      ).add(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      final state = dayStates[key];
      final color = switch (state) {
        OccurrenceState.completed => Colors.green.withValues(alpha: 0.75),
        OccurrenceState.missed => Colors.grey.withValues(alpha: 0.35),
        OccurrenceState.pending => Colors.transparent,
        null => Colors.transparent,
      };
      cells.add(
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('近 12 周', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(children: cells),
      ],
    );
  }
}

/// Streak 统计卡片
class StreakSummaryCard extends StatelessWidget {
  const StreakSummaryCard({super.key, required this.info});

  final StreakInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: '当前连续', value: '${info.current}', theme: theme),
            _Stat(label: '最长连续', value: '${info.longest}', theme: theme),
            _Stat(
              label: '完成率',
              value: '${(info.completionRate * 100).round()}%',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
