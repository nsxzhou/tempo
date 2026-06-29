import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../domain/recurrence_models.dart';

/// 重复规则选择器（间隔 + 单位 + 星期 + 结束条件）
class RepeatPicker extends StatefulWidget {
  const RepeatPicker({
    super.key,
    required this.config,
    required this.onChanged,
    this.enabled = true,
  });

  final RecurrenceConfig config;
  final ValueChanged<RecurrenceConfig> onChanged;
  final bool enabled;

  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

enum _RepeatEndMode { never, date, count }

class _RepeatPickerState extends State<RepeatPicker> {
  late RecurrenceConfig _config;
  _RepeatEndMode _endMode = _RepeatEndMode.never;
  DateTime? _endDate;
  int _endCount = 10;

  static const _weekdayLabels = {
    DateTime.monday: '一',
    DateTime.tuesday: '二',
    DateTime.wednesday: '三',
    DateTime.thursday: '四',
    DateTime.friday: '五',
    DateTime.saturday: '六',
    DateTime.sunday: '日',
  };

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _syncEndModeFromConfig();
  }

  void _syncEndModeFromConfig() {
    if (_config.endDate != null) {
      _endMode = _RepeatEndMode.date;
      _endDate = _config.endDate;
    } else if (_config.occurrenceCount != null) {
      _endMode = _RepeatEndMode.count;
      _endCount = _config.occurrenceCount!;
    } else {
      _endMode = _RepeatEndMode.never;
    }
  }

  void _emit() {
    final endDate = _endMode == _RepeatEndMode.date ? _endDate : null;
    final count = _endMode == _RepeatEndMode.count ? _endCount : null;
    _config = RecurrenceConfig(
      interval: _config.interval,
      unit: _config.unit,
      weekdays: _config.weekdays,
      endDate: endDate,
      occurrenceCount: count,
    );
    widget.onChanged(_config);
  }

  TempoTokens get t => context.tokens;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFrequencyRow(),
        if (_config.unit == RecurrenceUnit.week) ...[
          const SizedBox(height: 8),
          _buildWeekdayRow(),
        ],
        const SizedBox(height: 10),
        Text(
          '结束',
          style: AppTheme.mono(
            size: 10,
            weight: FontWeight.w700,
            color: t.fgMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        _buildEndModeRow(),
        if (_endMode == _RepeatEndMode.date) ...[
          const SizedBox(height: 8),
          _buildEndDatePill(),
        ],
        if (_endMode == _RepeatEndMode.count) ...[
          const SizedBox(height: 8),
          _buildEndCountRow(),
        ],
      ],
    );
  }

  Widget _buildFrequencyRow() {
    return Row(
      children: [
        Text(
          '每',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.fgSecondary,
          ),
        ),
        const SizedBox(width: 8),
        _buildStepper(
          value: _config.interval.clamp(1, 999),
          min: 1,
          max: 999,
          onChanged: (n) {
            setState(() => _config = RecurrenceConfig(
              interval: n,
              unit: _config.unit,
              weekdays: _config.weekdays,
              endDate: _config.endDate,
              occurrenceCount: _config.occurrenceCount,
            ));
            _emit();
          },
        ),
        const SizedBox(width: 8),
        _buildUnitPill('天', RecurrenceUnit.day),
        const SizedBox(width: 6),
        _buildUnitPill('周', RecurrenceUnit.week),
        const SizedBox(width: 6),
        _buildUnitPill('月', RecurrenceUnit.month),
      ],
    );
  }

  Widget _buildUnitPill(String label, RecurrenceUnit unit) {
    final isSelected = _config.unit == unit;
    return _buildOptionPill(
      label: label,
      selected: isSelected,
      minWidth: 32,
      onTap: () {
        if (isSelected) return;
        setState(() => _config = RecurrenceConfig(
          interval: _config.interval,
          unit: unit,
          weekdays: unit == RecurrenceUnit.week ? _config.weekdays : {},
          endDate: _config.endDate,
          occurrenceCount: _config.occurrenceCount,
        ));
        _emit();
      },
    );
  }

  Widget _buildWeekdayRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in _weekdayLabels.entries)
          _buildOptionPill(
            label: entry.value,
            selected: _config.weekdays.contains(entry.key),
            minWidth: 28,
            compact: true,
            onTap: () {
              setState(() {
                final days = Set<int>.from(_config.weekdays);
                if (days.contains(entry.key)) {
                  days.remove(entry.key);
                } else {
                  days.add(entry.key);
                }
                _config = RecurrenceConfig(
                  interval: _config.interval,
                  unit: _config.unit,
                  weekdays: days,
                  endDate: _config.endDate,
                  occurrenceCount: _config.occurrenceCount,
                );
              });
              _emit();
            },
          ),
      ],
    );
  }

  Widget _buildEndModeRow() {
    return Row(
      children: [
        _buildOptionPill(
          label: '永不',
          selected: _endMode == _RepeatEndMode.never,
          onTap: () {
            setState(() => _endMode = _RepeatEndMode.never);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        _buildOptionPill(
          label: '于日期',
          selected: _endMode == _RepeatEndMode.date,
          onTap: () {
            setState(() => _endMode = _RepeatEndMode.date);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        _buildOptionPill(
          label: '共 N 次',
          selected: _endMode == _RepeatEndMode.count,
          onTap: () {
            setState(() => _endMode = _RepeatEndMode.count);
            _emit();
          },
        ),
      ],
    );
  }

  Widget _buildEndDatePill() {
    final hasDate = _endDate != null;
    return GestureDetector(
      onTap: _pickEndDate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasDate ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: hasDate ? t.fg : t.borderStrong,
            width: hasDate ? 1 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 12,
              color: hasDate ? t.bg : t.fgSubtle,
            ),
            const SizedBox(width: 4),
            Text(
              hasDate
                  ? '${_endDate!.month}/${_endDate!.day}'
                  : '选择结束日期',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasDate ? t.bg : t.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await TempoDatePicker.show(
      context,
      initialDate: _endDate ?? now.add(const Duration(days: 90)),
      firstDate: today,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _emit();
    }
  }

  Widget _buildEndCountRow() {
    return Row(
      children: [
        Text(
          '共',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.fgSecondary,
          ),
        ),
        const SizedBox(width: 8),
        _buildStepper(
          value: _endCount.clamp(1, 9999),
          min: 1,
          max: 9999,
          onChanged: (n) {
            setState(() => _endCount = n);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        Text(
          '次',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.fgSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double? minWidth,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: selected ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? t.fg : t.borderStrong,
            width: selected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? t.bg : t.fgSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepperButton(
          icon: LucideIcons.minus,
          enabled: canDecrement,
          onTap: () => onChanged((value - 1).clamp(min, max)),
        ),
        Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.bgMuted,
            border: Border.symmetric(
              vertical: BorderSide(color: t.borderStrong, width: 0.8),
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.fg,
            ),
          ),
        ),
        _buildStepperButton(
          icon: LucideIcons.plus,
          enabled: canIncrement,
          onTap: () => onChanged((value + 1).clamp(min, max)),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: BorderRadius.only(
            topLeft: icon == LucideIcons.minus
                ? const Radius.circular(AppTheme.radiusSm)
                : Radius.zero,
            bottomLeft: icon == LucideIcons.minus
                ? const Radius.circular(AppTheme.radiusSm)
                : Radius.zero,
            topRight: icon == LucideIcons.plus
                ? const Radius.circular(AppTheme.radiusSm)
                : Radius.zero,
            bottomRight: icon == LucideIcons.plus
                ? const Radius.circular(AppTheme.radiusSm)
                : Radius.zero,
          ),
          border: Border.all(
            color: enabled ? t.borderStrong : t.borderSubtle,
            width: 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: enabled ? t.fg : t.fgFaint,
        ),
      ),
    );
  }
}

/// 编辑重复任务时的 iCal 作用范围
enum RecurrenceEditScope { thisOccurrence, thisAndFuture, all }

Future<RecurrenceEditScope?> showRecurrenceEditScopeSheet(
  BuildContext context,
) {
  return showModalBottomSheet<RecurrenceEditScope>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('仅此日程'),
            onTap: () => Navigator.pop(ctx, RecurrenceEditScope.thisOccurrence),
          ),
          ListTile(
            title: const Text('此日程及之后'),
            onTap: () => Navigator.pop(ctx, RecurrenceEditScope.thisAndFuture),
          ),
          ListTile(
            title: const Text('全部日程'),
            onTap: () => Navigator.pop(ctx, RecurrenceEditScope.all),
          ),
        ],
      ),
    ),
  );
}
