// ============================================================
// PlanPage — AI 日计划页(Stripe 派 1:1 还原 prototype PlanView.tsx)
// H1 + AI 智能排期 3 列卡 + 精力曲线 12 段 + 时间块列表
// + "重新进行精力排期" 按钮(用 mock 数据,业务未接入)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tempo/tempo.dart';

class _PlannerBlock {
  final String id;
  final String start;
  final String end;
  final String title;
  final String reason;
  final String tag; // calendar / p0 / p1 / p2 / p3 / break / buff
  bool active;
  _PlannerBlock({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    required this.reason,
    required this.tag,
    this.active = true,
  });
}

const _energyLevels = [2, 3, 4, 4, 3, 2, 1, 1, 2, 3, 3, 2];
const _energyTimes = ['8', '10', '12', '14', '16', '18', '20'];

final _mockBlocks = [
  _PlannerBlock(
    id: '1',
    start: '09:00',
    end: '10:30',
    title: '整理本周关键产出 OKR',
    reason: 'P0 优先级聚焦,符合当前脑值黄金时段',
    tag: 'p0',
    active: true,
  ),
  _PlannerBlock(
    id: '2',
    start: '10:30',
    end: '11:00',
    title: '审阅 PRD 草稿并留批注',
    reason: '高密度阅读任务,匹配上午高效窗口',
    tag: 'p1',
    active: true,
  ),
  _PlannerBlock(
    id: '3',
    start: '11:00',
    end: '12:00',
    title: '与产品同步版本路线图',
    reason: '日程订阅冲突,需实时沟通',
    tag: 'calendar',
    active: true,
  ),
  _PlannerBlock(
    id: '4',
    start: '12:00',
    end: '13:00',
    title: '午餐 + 短暂散步',
    reason: '脑力恢复时段,保护下午精力',
    tag: 'break',
    active: true,
  ),
  _PlannerBlock(
    id: '5',
    start: '14:00',
    end: '15:00',
    title: '回复团队 Slack 消息',
    reason: '轻量收尾,午后第一波注意力回升',
    tag: 'buff',
    active: true,
  ),
  _PlannerBlock(
    id: '6',
    start: '15:00',
    end: '16:30',
    title: '撰写技术方案初稿',
    reason: 'P2 中等优先级,需持续专注',
    tag: 'p2',
    active: false,
  ),
  _PlannerBlock(
    id: '7',
    start: '16:30',
    end: '17:00',
    title: '梳理明日任务清单',
    reason: '低精力时段,适合归纳整理',
    tag: 'p3',
    active: true,
  ),
];

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  late List<_PlannerBlock> _blocks;
  bool _isReplanning = false;

  @override
  void initState() {
    super.initState();
    _blocks = List.of(_mockBlocks);
  }

  Future<void> _replan() async {
    setState(() => _isReplanning = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      // 简单 mock:反转 active 状态
      for (final b in _blocks) {
        b.active = !b.active;
      }
      _isReplanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = '${now.month} 月 ${now.day} 日 · 周${_cnWeekday(now.weekday)}';
    final activeCount = _blocks.where((b) => b.active).length;
    final totalMinutes = activeCount * 60.0; // mock
    final hours = totalMinutes / 60;
    final hoursStr = hours.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今日计划',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSubtle,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: AppTheme.borderStrong,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.fg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'V2.0',
                                style: AppTheme.mono(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: AppTheme.fgSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // AI 智能排期 3 列卡
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _AiOverviewCard(
                      scheduled: activeCount,
                      hours: hoursStr,
                      match: '82%',
                    ),
                  ),

                  // 精力曲线
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _EnergyCard(
                      levels: _energyLevels,
                      times: _energyTimes,
                    ),
                  ),

                  // 流程排期
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BlocksSection(
                      isReplanning: _isReplanning,
                      blocks: _blocks,
                      onToggle: (id) => setState(() {
                        _blocks.firstWhere((b) => b.id == id).active =
                            !_blocks.firstWhere((b) => b.id == id).active;
                      }),
                    ),
                  ),

                  // 重新排期按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ReplanButton(
                      isLoading: _isReplanning,
                      onTap: _replan,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _cnWeekday(int wd) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[(wd - 1) % 7];
  }
}

// (removed copy_with_text extension; using Text widget directly)

class _AiOverviewCard extends StatelessWidget {
  final int scheduled;
  final String hours;
  final String match;
  const _AiOverviewCard({
    required this.scheduled,
    required this.hours,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // 顶部 label + ACTIVE 徽章
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: AppTheme.fg,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI 智能排排期',
                  style: AppTheme.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppTheme.fgMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                TempoPillBadge(
                  label: 'ACTIVE',
                  kind: TempoBadgeKind.active,
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.borderSubtle),
          // 3 列
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TempoStatTile(
                    value: '$scheduled 个',
                    label: '已排期任务',
                  ),
                ),
                Container(width: 1, color: AppTheme.borderStrong),
                Expanded(
                  child: TempoStatTile(
                    value: '$hours 小时',
                    label: '排程时长',
                  ),
                ),
                Container(width: 1, color: AppTheme.borderStrong),
                Expanded(
                  child: TempoStatTile(
                    value: match,
                    label: '脑值匹配',
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final List<int> levels;
  final List<String> times;
  const _EnergyCard({required this.levels, required this.times});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderStrong, width: 0.8),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日精力曲线',
                style: AppTheme.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.fgMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const TempoHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 12),
          TempoHeatmapBar(levels: levels, times: times, height: 40),
        ],
      ),
    );
  }
}

class _BlocksSection extends StatelessWidget {
  final bool isReplanning;
  final List<_PlannerBlock> blocks;
  final ValueChanged<String> onToggle;
  const _BlocksSection({
    required this.isReplanning,
    required this.blocks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TempoSectionHeader(label: '流程排期 · ${blocks.length}'),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isReplanning
              ? const _ReplanningPlaceholder(key: ValueKey('replan'))
              : Column(
                  key: const ValueKey('blocks'),
                  children: [
                    for (int i = 0; i < blocks.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      _PlannerBlockTile(
                        block: blocks[i],
                        isLast: i == blocks.length - 1,
                        onToggle: () => onToggle(blocks[i].id),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReplanningPlaceholder extends StatelessWidget {
  const _ReplanningPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation(AppTheme.fg),
              backgroundColor: AppTheme.bgMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tempo 正在为您重新优化时间窗并排期…',
            style: AppTheme.mono(
              size: 11,
              color: AppTheme.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerBlockTile extends StatelessWidget {
  final _PlannerBlock block;
  final bool isLast;
  final VoidCallback onToggle;
  const _PlannerBlockTile({
    required this.block,
    required this.isLast,
    required this.onToggle,
  });

  String get _tagLabel {
    switch (block.tag) {
      case 'calendar':
        return '日程订阅';
      case 'break':
        return '脑力保护 🌴';
      case 'buff':
        return '轻量收尾 🗃️';
      case 'p0':
      case 'p1':
      case 'p2':
      case 'p3':
        return '${block.tag.toUpperCase()} 专注';
      default:
        return block.tag.toUpperCase();
    }
  }

  TempoBadgeKind get _tagKind {
    switch (block.tag) {
      case 'p0':
        return TempoBadgeKind.p0;
      case 'p1':
        return TempoBadgeKind.p1;
      case 'p2':
        return TempoBadgeKind.p2;
      case 'p3':
        return TempoBadgeKind.p3;
      case 'calendar':
        return TempoBadgeKind.neutral;
      case 'break':
        return TempoBadgeKind.success;
      default:
        return TempoBadgeKind.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 54,
            top: 38,
            bottom: -16,
            child: Container(
              width: 1.5,
              color: block.active ? AppTheme.fg : AppTheme.borderStrong,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间列
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      block.start,
                      style: AppTheme.mono(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppTheme.fg,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      block.end,
                      style: AppTheme.mono(
                        size: 10,
                        color: AppTheme.fgMuted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 圆点
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TempoProgressDot(
                  active: block.active,
                  onTap: onToggle,
                ),
              ),
              const SizedBox(width: 12),
              // 内容卡
              Expanded(
                child: GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: block.active
                            ? AppTheme.fg
                            : AppTheme.borderStrong,
                        width: 0.8,
                      ),
                      boxShadow: block.active
                          ? const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          block.reason,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.fgMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TempoPillBadge(label: _tagLabel, kind: _tagKind),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplanButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _ReplanButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: const BorderSide(color: AppTheme.borderStrong, width: 0.8),
        ),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.refresh_cw,
                  size: 14,
                  color: isLoading ? AppTheme.fgMuted : AppTheme.fg,
                ),
                const SizedBox(width: 6),
                Text(
                  '重新进行精力排期',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isLoading ? AppTheme.fgMuted : AppTheme.fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
