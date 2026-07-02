// TempoDatePicker — Tempo 风格日历选择器底部 sheet
// 完全自定义 UI,替代 Flutter 原生 showDatePicker
// 中文日期格式 + Geist 字体 + 黑白极简配色
// 特性: 今天小圆点标记、可选范围灰色不可点、月份滑动切换

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tempo_theme_extension.dart';
import '../../../motion/tempo_sheet.dart';
import '../../../utils/date_utils.dart';

/// Tempo 风格日历选择器
///
/// 弹出底部 sheet 展示日历网格,支持日期范围限制和今天标记。
/// 返回选中的 DateTime,取消返回 null。
class TempoDatePicker {
  /// 弹出 Tempo 风格日历选择器底部 sheet
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return TempoSheet.show<DateTime>(
      context: context,
      enableDrag: false,
      builder: (_) => _DatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DatePickerSheet({
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _displayMonth;
  DateTime? _selectedDate;

  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(
      (widget.initialDate ?? widget.firstDate).year,
      (widget.initialDate ?? widget.firstDate).month,
    );
  }

  // ─── 月份导航 ───

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  bool get _canGoPrev => canNavigateToPreviousMonth(
    displayMonth: _displayMonth,
    firstDate: widget.firstDate,
  );

  bool get _canGoNext {
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    return nextMonth.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month + 1),
    );
  }

  // ─── 日期判断 ───

  bool _isInRange(DateTime date) {
    final d = calendarDay(date);
    final first = calendarDay(widget.firstDate);
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return !d.isBefore(first) && !d.isAfter(last);
  }

  bool _isToday(DateTime date) => isSameDay(date, DateTime.now());

  // ─── 格式化 ───

  String _formatPreview(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}月${date.day}日 · ${weekdays[date.weekday - 1]}';
  }

  String _formatMonthTitle(DateTime date) {
    return '${date.year}年${date.month}月';
  }

  // ─── 选择与确认 ───

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _confirm() {
    if (_selectedDate != null) {
      Navigator.of(context).pop(_selectedDate);
    }
  }

  // ─── 构建 ───

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
            // 拖拽指示条
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

            // 日期预览
            _buildDatePreview(),
            const SizedBox(height: 16),

            // 月份导航
            _buildMonthNav(),
            const SizedBox(height: 12),

            // 星期标题
            _buildWeekdayHeaders(),
            const SizedBox(height: 4),

            // 日历网格
            _buildCalendarGrid(),
            const SizedBox(height: 20),

            // 操作按钮
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePreview() {
    final t = context.tokens;
    final date = _selectedDate ?? _displayMonth;
    return Text(
      _formatPreview(date),
      style: TextStyle(
        fontFamily: AppTheme.fontSans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: t.fg,
      ),
    );
  }

  Widget _buildMonthNav() {
    final t = context.tokens;
    return Row(
      children: [
        GestureDetector(
          onTap: _canGoPrev ? _prevMonth : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                LucideIcons.chevron_left,
                size: 16,
                color: _canGoPrev ? t.fg : t.fgFaint,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            _formatMonthTitle(_displayMonth),
            textAlign: TextAlign.center,
            style: t.mono(size: 13, weight: FontWeight.w600, color: t.fg),
          ),
        ),
        GestureDetector(
          onTap: _canGoNext ? _nextMonth : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                LucideIcons.chevron_right,
                size: 16,
                color: _canGoNext ? t.fg : t.fgFaint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final t = context.tokens;
    return Row(
      children: [
        for (final day in _weekdays)
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: t.mono(
                size: 11,
                weight: FontWeight.w500,
                color: t.fgMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month);
    // DateTime.weekday: Mon=1..Sun=7, 日历从周日开始
    final startWeekday = firstDayOfMonth.weekday % 7; // Sun=0
    final daysInMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
    ).day;

    final cells = <Widget>[];

    // 前置空白
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(height: 40));
    }

    // 日期格
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, day);
      cells.add(_buildDayCell(date));
    }

    return Wrap(
      spacing: 0,
      runSpacing: 2,
      children: [
        for (final cell in cells)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 7,
            child: cell,
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final t = context.tokens;
    final isSelected = _selectedDate != null && isSameDay(date, _selectedDate!);
    final isToday = _isToday(date);
    final inRange = _isInRange(date);

    // 选中态: 黑底白字
    if (isSelected) {
      return GestureDetector(
        onTap: () => _selectDate(date),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: t.fg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: AppTheme.fontSans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.bg,
            ),
          ),
        ),
      );
    }

    // 不可选: 灰色
    if (!inRange) {
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontFamily: AppTheme.fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: t.fgFaint,
          ),
        ),
      );
    }

    // 今天: 小圆点标记
    final todayDot = isToday
        ? Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: t.fg, shape: BoxShape.circle),
            ),
          )
        : const SizedBox(height: 5);

    return GestureDetector(
      onTap: () => _selectDate(date),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontFamily: AppTheme.fontSans,
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: t.fg,
              ),
            ),
            todayDot,
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final t = context.tokens;
    return Row(
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
            onTap: _selectedDate != null ? _confirm : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _selectedDate != null ? t.fg : t.bgMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                '确定',
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedDate != null ? t.bg : t.fgSubtle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 判断能否导航到上一月。
bool canNavigateToPreviousMonth({
  required DateTime displayMonth,
  required DateTime firstDate,
}) {
  final prevMonth = DateTime(displayMonth.year, displayMonth.month - 1);
  final firstMonth = DateTime(firstDate.year, firstDate.month);
  return !prevMonth.isBefore(firstMonth);
}
