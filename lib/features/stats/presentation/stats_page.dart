import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/tempo_theme_extension.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/stats_models.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final days = ref.watch(statsDaysProvider);
    final dailyAsync = ref.watch(dailyCompletionsProvider(days));
    final snapshot = ref.watch(statsSnapshotProvider(days));

    final daily =
        dailyAsync.valueOrNull ??
        List.generate(days, (i) {
          final start = DateTime.now().subtract(Duration(days: days - 1 - i));
          return DailyCompletion(
            date: calendarDay(start),
            count: 0,
          );
        });

    final periodLabel = days == 7 ? '近 7 天' : '近 30 天';
    final tokens = context.tokens;
    final scaffoldBg = ref.watch(scaffoldBackgroundProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '统计',
                      style: tokens.sansSemibold(
                        size: 32,
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      periodLabel,
                      style: tokens.mono(
                        size: 12,
                        color: tokens.fgMuted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _PeriodToggle(
                  days: days,
                  onChanged: (value) =>
                      ref.read(statsDaysProvider.notifier).state = value,
                ),
              ),
              _StatsChartsGroup(
                daily: daily,
                snapshot: snapshot,
                periodLabel: periodLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7 天')),
        ButtonSegment(value: 30, label: Text('30 天')),
      ],
      selected: {days},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: t.fg,
        selectedForegroundColor: t.bg,
        foregroundColor: t.fgMuted,
        side: BorderSide(color: t.borderStrong),
        textStyle: t.mono(size: 11, weight: FontWeight.w600),
      ),
    );
  }
}

class _StatsChartsGroup extends StatelessWidget {
  final List<DailyCompletion> daily;
  final StatsSnapshot snapshot;
  final String periodLabel;

  const _StatsChartsGroup({
    required this.daily,
    required this.snapshot,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TempoGlassSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HealthMetricsGrid(
              health: snapshot.health,
              periodLabel: periodLabel,
            ),
            const SizedBox(height: 20),
            _StatsSubsection(
              title: '完成量趋势',
              subtitle: periodLabel,
              child: RepaintBoundary(
                child: _CompletionTrendChart(daily: daily),
              ),
            ),
            const SizedBox(height: 20),
            _StatsSubsection(
              title: '$periodLabel 创建任务完成率',
              child: _CompletionRateBar(rate: snapshot.completionRate),
            ),
            const SizedBox(height: 20),
            _StatsSubsection(
              title: '分类结构',
              subtitle: '未完成待办',
              child: RepaintBoundary(
                child: _CategoryBars(slices: snapshot.categorySlices),
              ),
            ),
            const SizedBox(height: 20),
            _StatsSubsection(
              title: '优先级压力',
              subtitle: '未完成待办',
              child: RepaintBoundary(
                child: _PriorityBars(slices: snapshot.prioritySlices),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricsGrid extends StatelessWidget {
  final StatsHealth health;
  final String periodLabel;

  const _HealthMetricsGrid({required this.health, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _HealthMetricTile(label: '待处理', value: '${health.pending}'),
        _HealthMetricTile(
          label: '已逾期',
          value: '${health.overdue}',
          tone: _HealthMetricTone.danger,
        ),
        _HealthMetricTile(label: '本周到期', value: '${health.weekDue}'),
        _HealthMetricTile(
          label: '$periodLabel 完成',
          value: '${health.completedInPeriod}',
          tone: _HealthMetricTone.success,
        ),
      ],
    );
  }
}

enum _HealthMetricTone { neutral, danger, success }

class _HealthMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final _HealthMetricTone tone;

  const _HealthMetricTile({
    required this.label,
    required this.value,
    this.tone = _HealthMetricTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final valueColor = switch (tone) {
      _HealthMetricTone.danger => AppTheme.priorityP0,
      _HealthMetricTone.success => t.success,
      _HealthMetricTone.neutral => t.fg,
    };
    final bg = switch (tone) {
      _HealthMetricTone.danger => AppTheme.priorityP0Bg,
      _HealthMetricTone.success => t.successBg,
      _HealthMetricTone.neutral => t.bgMuted,
    };
    final border = switch (tone) {
      _HealthMetricTone.danger => AppTheme.priorityP0Border,
      _HealthMetricTone.success => AppTheme.successBorder,
      _HealthMetricTone.neutral => t.borderStrong,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.mono(
              size: 9,
              weight: FontWeight.w700,
              color: t.fgMuted,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: t.mono(
              size: 22,
              weight: FontWeight.w700,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSubsection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _StatsSubsection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.sansSemibold(size: 15, letterSpacing: -0.3)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: t.mono(size: 9, color: t.fgSubtle)),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _CompletionTrendChart extends StatelessWidget {
  final List<DailyCompletion> daily;

  const _CompletionTrendChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (daily.every((d) => d.count == 0)) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('暂无完成记录', style: t.mono(size: 12, color: t.fgMuted)),
        ),
      );
    }

    final maxY = daily.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final spots = [
      for (var i = 0; i < daily.length; i++)
        FlSpot(i.toDouble(), daily[i].count.toDouble()),
    ];

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY + 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: t.borderSubtle, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, _) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: t.mono(size: 9, color: t.fgSubtle),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: daily.length <= 7 ? 1 : 5,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= daily.length) {
                    return const SizedBox.shrink();
                  }
                  if (daily.length > 7 &&
                      index % 5 != 0 &&
                      index != daily.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('M/d').format(daily[index].date),
                      style: t.mono(size: 9, color: t.fgSubtle),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: t.borderStrong),
              left: BorderSide(color: t.borderStrong),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: t.fg,
              barWidth: 2,
              dotData: FlDotData(
                show: daily.length <= 7,
                getDotPainter: (_, _, _, _) =>
                    FlDotCirclePainter(radius: 3, color: t.fg, strokeWidth: 0),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBars extends StatelessWidget {
  final List<PrioritySlice> slices;

  const _PriorityBars({required this.slices});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (slices.isEmpty) {
      return _emptyChart(context, '暂无带优先级的待办');
    }

    return _DistributionBars(
      rows: [
        for (final slice in slices)
          _DistributionRowData(
            label: slice.label,
            count: slice.count,
            color: t.priorityColor(slice.priority.value),
          ),
      ],
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final List<CategorySlice> slices;

  const _CategoryBars({required this.slices});

  Color _colorFor(BuildContext context, String id) {
    final t = context.tokens;
    switch (id) {
      case 'work':
        return t.fg;
      case 'life':
        return t.success;
      default:
        return t.fgMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return _emptyChart(context, '暂无待办任务');
    }

    return _DistributionBars(
      rows: [
        for (final slice in slices)
          _DistributionRowData(
            label: slice.label,
            count: slice.count,
            color: _colorFor(context, slice.id),
          ),
      ],
    );
  }
}

class _DistributionRowData {
  final String label;
  final int count;
  final Color color;

  const _DistributionRowData({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _DistributionBars extends StatelessWidget {
  final List<_DistributionRowData> rows;

  const _DistributionBars({required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final maxCount = rows.fold<int>(
      0,
      (current, row) => row.count > current ? row.count : current,
    );

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _DistributionBarRow(row: rows[i], maxCount: maxCount),
          if (i != rows.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: t.borderSubtle),
            ),
        ],
      ],
    );
  }
}

class _DistributionBarRow extends StatelessWidget {
  final _DistributionRowData row;
  final int maxCount;

  const _DistributionBarRow({required this.row, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ratio = maxCount == 0 ? 0.0 : row.count / maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                style: t.sansSemibold(size: 12, color: t.fgSecondary),
              ),
            ),
            Text(
              '${row.count}',
              style: t.mono(size: 12, weight: FontWeight.w700, color: t.fg),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: Container(
            height: 8,
            color: t.bgMuted,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(color: row.color),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionRateBar extends StatelessWidget {
  final CompletionRate rate;

  const _CompletionRateBar({required this.rate});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${rate.percent}%',
              style: t.mono(
                size: 28,
                weight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${rate.completed} / ${rate.total} 项',
                style: t.mono(size: 11, color: t.fgMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: LinearProgressIndicator(
            value: rate.total == 0 ? 0 : rate.ratio,
            minHeight: 8,
            backgroundColor: t.bgMuted,
            color: t.fg,
          ),
        ),
      ],
    );
  }
}

Widget _emptyChart(BuildContext context, String message) {
  final t = context.tokens;
  return SizedBox(
    height: 120,
    child: Center(
      child: Text(message, style: t.mono(size: 12, color: t.fgMuted)),
    ),
  );
}
