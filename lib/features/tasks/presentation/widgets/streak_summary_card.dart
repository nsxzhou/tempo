import 'package:flutter/material.dart';

import '../../domain/recurrence_models.dart';

/// Streak 统计卡片
class StreakSummaryCard extends StatelessWidget {
  const StreakSummaryCard({super.key, required this.info});

  final StreakInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = <Widget>[
      _Stat(label: '当前连续', value: '${info.current}', theme: theme),
      _Stat(label: '最长连续', value: '${info.longest}', theme: theme),
      if (info.hasSeriesCap)
        _Stat(
          label: '进度',
          value: info.seriesProgressLabel!,
          theme: theme,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats,
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
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
