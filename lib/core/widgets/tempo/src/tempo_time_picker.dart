// TempoTimePicker — Tempo 风格时间选择器底部 sheet
// 双列滚轮（时/分）+ 预览 + 取消/确定

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tempo_theme_extension.dart';
import '../../../motion/tempo_sheet.dart';

/// Tempo 风格时间选择器
class TempoTimePicker {
  TempoTimePicker._();

  /// 弹出 Tempo 风格时间选择器底部 sheet
  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) {
    return TempoSheet.show<TimeOfDay>(
      context: context,
      enableDrag: false,
      builder: (_) => _TimePickerSheet(
        initialTime: initialTime ?? const TimeOfDay(hour: 9, minute: 0),
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const _TimePickerSheet({required this.initialTime});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  static const _itemExtent = 44.0;
  static const _visibleItems = 5;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _confirm() {
    Navigator.of(
      context,
    ).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int index) labelBuilder,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.6,
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final t = context.tokens;
            final isSelected = controller.selectedItem == index;
            return Center(
              child: Text(
                labelBuilder(index),
                style: t.mono(
                  size: isSelected ? 20 : 16,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? t.fg : t.fgMuted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderStrong,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatTime(_selectedHour, _selectedMinute),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontSans,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.fg,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _itemExtent * _visibleItems,
              child: Row(
                children: [
                  _buildWheel(
                    controller: _hourController,
                    itemCount: 24,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedHour = index);
                    },
                    labelBuilder: (index) => index.toString().padLeft(2, '0'),
                  ),
                  Text(
                    ':',
                    style: t.mono(
                      size: 20,
                      weight: FontWeight.w700,
                      color: t.fg,
                    ),
                  ),
                  _buildWheel(
                    controller: _minuteController,
                    itemCount: 60,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedMinute = index);
                    },
                    labelBuilder: (index) => index.toString().padLeft(2, '0'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: t.borderStrong, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontFamily: AppTheme.fontSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: t.fgMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _confirm,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.fg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: AppTheme.fontSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.bg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
