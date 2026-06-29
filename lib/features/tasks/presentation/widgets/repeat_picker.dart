import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('每', style: theme.textTheme.bodyMedium),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextFormField(
                initialValue: '${_config.interval.clamp(1, 999)}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 1;
                  setState(() => _config = RecurrenceConfig(
                    interval: n.clamp(1, 999),
                    unit: _config.unit,
                    weekdays: _config.weekdays,
                    endDate: _config.endDate,
                    occurrenceCount: _config.occurrenceCount,
                  ));
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<RecurrenceUnit>(
              value: _config.unit,
              items: const [
                DropdownMenuItem(value: RecurrenceUnit.day, child: Text('天')),
                DropdownMenuItem(value: RecurrenceUnit.week, child: Text('周')),
                DropdownMenuItem(
                  value: RecurrenceUnit.month,
                  child: Text('月'),
                ),
              ],
              onChanged: (u) {
                if (u == null) return;
                setState(() => _config = RecurrenceConfig(
                  interval: _config.interval,
                  unit: u,
                  weekdays: u == RecurrenceUnit.week ? _config.weekdays : {},
                  endDate: _config.endDate,
                  occurrenceCount: _config.occurrenceCount,
                ));
                _emit();
              },
            ),
          ],
        ),
        if (_config.unit == RecurrenceUnit.week) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              for (final entry in const {
                DateTime.monday: '一',
                DateTime.tuesday: '二',
                DateTime.wednesday: '三',
                DateTime.thursday: '四',
                DateTime.friday: '五',
                DateTime.saturday: '六',
                DateTime.sunday: '日',
              }.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _config.weekdays.contains(entry.key),
                  onSelected: (sel) {
                    setState(() {
                      final days = Set<int>.from(_config.weekdays);
                      if (sel) {
                        days.add(entry.key);
                      } else {
                        days.remove(entry.key);
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
          ),
        ],
        const SizedBox(height: 8),
        SegmentedButton<_RepeatEndMode>(
          segments: const [
            ButtonSegment(value: _RepeatEndMode.never, label: Text('永不')),
            ButtonSegment(value: _RepeatEndMode.date, label: Text('于日期')),
            ButtonSegment(value: _RepeatEndMode.count, label: Text('共 N 次')),
          ],
          selected: {_endMode},
          onSelectionChanged: (s) {
            setState(() => _endMode = s.first);
            _emit();
          },
        ),
        if (_endMode == _RepeatEndMode.date)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _endDate == null
                  ? '选择结束日期'
                  : '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}',
            ),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
                _emit();
              }
            },
          ),
        if (_endMode == _RepeatEndMode.count)
          Row(
            children: [
              const Text('共'),
              SizedBox(
                width: 64,
                child: TextFormField(
                  initialValue: '$_endCount',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v) {
                    _endCount = (int.tryParse(v) ?? 10).clamp(1, 9999);
                    _emit();
                  },
                ),
              ),
              const Text('次'),
            ],
          ),
      ],
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
