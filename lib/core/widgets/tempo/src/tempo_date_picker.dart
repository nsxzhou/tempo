// TempoDatePicker — Tempo 风格日历选择器底部 sheet
// 完全自定义 UI,替代 Flutter 原生 showDatePicker
// 中文日期格式 + Geist 字体 + 黑白极简配色
// 特性: 今天小圆点标记、可选范围灰色不可点、月份滑动切换

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../theme/app_theme.dart';

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
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
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

  bool get _canGoPrev {
    final prevMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    return prevMonth.isAfter(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  bool get _canGoNext {
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    return nextMonth.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month + 1),
    );
  }

  // ─── 日期判断 ───

  bool _isInRange(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final first = DateTime(
        widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(
        widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !d.isBefore(first) && !d.isAfter(last);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());

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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: [
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
                  color: AppTheme.borderStrong,
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
    final date = _selectedDate ?? _displayMonth;
    return Text(
      _formatPreview(date),
      style: const TextStyle(
        fontFamily: AppTheme.fontSans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.fg,
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      children: [
        GestureDetector(
          onTap: _canGoPrev ? _prevMonth : null,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.chevron_left,
              size: 16,
              color: _canGoPrev ? AppTheme.fg : AppTheme.fgFaint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            _formatMonthTitle(_displayMonth),
            textAlign: TextAlign.center,
            style: AppTheme.mono(
              size: 13,
              weight: FontWeight.w600,
              color: AppTheme.fg,
            ),
          ),
        ),
        GestureDetector(
          onTap: _canGoNext ? _nextMonth : null,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: _canGoNext ? AppTheme.fg : AppTheme.fgFaint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    return Row(
      children: [
        for (final day in _weekdays)
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: AppTheme.mono(
                size: 11,
                weight: FontWeight.w500,
                color: AppTheme.fgMuted,
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
    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
    final isToday = _isToday(date);
    final inRange = _isInRange(date);

    // 选中态: 黑底白字
    if (isSelected) {
      return GestureDetector(
        onTap: () => _selectDate(date),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppTheme.fg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: const TextStyle(
              fontFamily: AppTheme.fontSans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.bg,
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
          style: const TextStyle(
            fontFamily: AppTheme.fontSans,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.fgFaint,
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
              decoration: BoxDecoration(
                color: AppTheme.fg,
                shape: BoxShape.circle,
              ),
            ),
          )
        : const SizedBox(height: 5);

    return GestureDetector(
      onTap: () => _selectDate(date),
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
                fontWeight:
                    isToday ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.fg,
              ),
            ),
            todayDot,
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderStrong, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Text(
                '取消',
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.fgMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _selectedDate != null ? _confirm : null,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color:
                    _selectedDate != null ? AppTheme.fg : AppTheme.bgMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                '确定',
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      _selectedDate != null ? AppTheme.bg : AppTheme.fgSubtle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
