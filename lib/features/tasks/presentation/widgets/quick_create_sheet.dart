// QuickCreateSheet — 快速创建底部抽屉
// 折叠式:默认只标题+创建按钮;展开后显示日期pills(今天/明天/后天/下周一)+优先级pills(P0~P3)
// 创建后关闭sheet→undo snackbar 5s真删除

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';

/// 日期快捷选项
enum _QuickDate {
  today('今天'),
  tomorrow('明天'),
  dayAfter('后天'),
  nextMonday('下周一');

  final String label;
  const _QuickDate(this.label);

  /// 计算 _QuickDate 对应的 DateTime（取当天开始 00:00）
  DateTime? toDateTime() {
    final now = DateTime.now();
    switch (this) {
      case _QuickDate.today:
        return DateTime(now.year, now.month, now.day);
      case _QuickDate.tomorrow:
        return DateTime(now.year, now.month, now.day + 1);
      case _QuickDate.dayAfter:
        return DateTime(now.year, now.month, now.day + 2);
      case _QuickDate.nextMonday:
        // 找下一个周一
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        final offset = daysUntilMonday == 0 ? 7 : daysUntilMonday;
        return DateTime(now.year, now.month, now.day + offset);
    }
  }
}

/// 快速创建回调：返回创建成功的 Task id，供 undo 用
typedef QuickCreateCallback = Future<String> Function({
  required String title,
  DateTime? dueDate,
  TaskPriority priority,
});

class QuickCreateSheet extends StatefulWidget {
  final QuickCreateCallback onCreate;

  const QuickCreateSheet({super.key, required this.onCreate});

  /// 从 TasksPage 弹出快速创建 bottom sheet
  static Future<void> show(BuildContext context, {required QuickCreateCallback onCreate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000), // 和 VoiceOverlay 一致 black/45
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => QuickCreateSheet(onCreate: onCreate),
    );
  }

  @override
  State<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<QuickCreateSheet> {
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();

  bool _expanded = false;
  _QuickDate? _selectedDate;
  DateTime? _customDate;
  TaskPriority _selectedPriority = TaskPriority.none;

  bool _isSubmitting = false;

  bool get _canSubmit => _titleController.text.trim().isNotEmpty && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    // 自动聚焦标题输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// 获取最终 dueDate（pills 或自定义）
  DateTime? get _effectiveDueDate {
    if (_customDate != null) return _customDate;
    return _selectedDate?.toDateTime();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onCreate(
        title: _titleController.text.trim(),
        dueDate: _effectiveDueDate,
        priority: _selectedPriority,
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭 sheet
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: $e', style: const TextStyle(fontSize: 12, color: AppTheme.bg)),
          backgroundColor: AppTheme.priorityP0,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 键盘高度自适应
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          border: Border(top: BorderSide(color: AppTheme.borderStrong, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            // 标题输入框
            _buildTitleField(),
            const SizedBox(height: 10),
            // 折叠展开区
            _buildExpandToggle(),
            if (_expanded) ...[
              const SizedBox(height: 14),
              _buildDateSection(),
              const SizedBox(height: 14),
              _buildPrioritySection(),
            ],
            const SizedBox(height: 14),
            // 创建按钮
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocus,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.fg,
      ),
      decoration: InputDecoration(
        hintText: '拟定待办…',
        hintStyle: TextStyle(color: AppTheme.fgSubtle, fontSize: 14),
        filled: true,
        fillColor: AppTheme.bgSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.fg, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: _titleController.text.isNotEmpty
            ? IconButton(
                icon: Icon(LucideIcons.x, size: 14, color: AppTheme.fgSubtle),
                onPressed: () {
                  _titleController.clear();
                  _titleFocus.requestFocus();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            : null,
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildExpandToggle() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Row(
        children: [
          Icon(
            _expanded ? LucideIcons.chevron_down : LucideIcons.chevron_right,
            size: 14,
            color: AppTheme.fgMuted,
          ),
          const SizedBox(width: 6),
          Text(
            _expanded ? '更多选项' : '更多选项',
            style: AppTheme.mono(
              size: 11,
              color: AppTheme.fgMuted,
              letterSpacing: 0.4,
            ),
          ),
          if (_effectiveDueDate != null || _selectedPriority != TaskPriority.none) ...[
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.fg,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════ 日期 pills ══════════════

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '截止日期',
          style: AppTheme.mono(
            size: 10,
            weight: FontWeight.w700,
            color: AppTheme.fgMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final date in _QuickDate.values) ...[
              if (date != _QuickDate.values.first) const SizedBox(width: 8),
              _buildDatePill(date),
            ],
            const SizedBox(width: 8),
            _buildCustomDateButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePill(_QuickDate date) {
    final isSelected = _selectedDate == date && _customDate == null;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            // toggle 取消 → 回到无日期
            _selectedDate = null;
          } else {
            _selectedDate = date;
            _customDate = null; // 选 pill 时清除自定义日期
          }
        });
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.fg : AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.fg : AppTheme.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          date.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.bg : AppTheme.fgSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateButton() {
    final hasCustom = _customDate != null;
    return GestureDetector(
      onTap: _pickCustomDate,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasCustom ? AppTheme.fg : AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: hasCustom ? AppTheme.fg : AppTheme.borderStrong,
            width: hasCustom ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 12,
              color: hasCustom ? AppTheme.bg : AppTheme.fgSubtle,
            ),
            const SizedBox(width: 4),
            Text(
              hasCustom ? _formatDate(_customDate!) : '自定义',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasCustom ? AppTheme.bg : AppTheme.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.light.copyWith(
            colorScheme: AppTheme.light.colorScheme.copyWith(
              primary: AppTheme.fg,
              onPrimary: AppTheme.bg,
              surface: AppTheme.bg,
              onSurface: AppTheme.fg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDate = DateTime(picked.year, picked.month, picked.day);
        _selectedDate = null; // 自定义日期时清除 pill 选中
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // ══════════════ 优先级 pills ══════════════

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '优先级',
          style: AppTheme.mono(
            size: 10,
            weight: FontWeight.w700,
            color: AppTheme.fgMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final p in [TaskPriority.p0, TaskPriority.p1, TaskPriority.p2, TaskPriority.p3]) ...[
              if (p != TaskPriority.p0) const SizedBox(width: 8),
              _buildPriorityPill(p),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityPill(TaskPriority p) {
    final isSelected = _selectedPriority == p;
    final label = p.label ?? p.name.toUpperCase();
    // 选中态用对应优先级色，未选中用中性色
    final activeBg = _priorityActiveBg(p);
    final activeFg = _priorityActiveFg(p);
    final activeBorder = _priorityActiveBorder(p);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            // toggle 取消 → 回到 none
            _selectedPriority = TaskPriority.none;
          } else {
            _selectedPriority = p;
          }
        });
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? activeBorder : AppTheme.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? activeFg : AppTheme.fgSecondary,
          ),
        ),
      ),
    );
  }

  Color _priorityActiveBg(TaskPriority p) {
    return switch (p) {
      TaskPriority.p0 => AppTheme.priorityP0Bg,
      TaskPriority.p1 => AppTheme.priorityP1Bg,
      TaskPriority.p2 => AppTheme.priorityP2Bg,
      TaskPriority.p3 => AppTheme.priorityP3Bg,
      TaskPriority.none => AppTheme.bgMuted,
    };
  }

  Color _priorityActiveFg(TaskPriority p) {
    return switch (p) {
      TaskPriority.p0 => AppTheme.priorityP0,
      TaskPriority.p1 => AppTheme.priorityP1,
      TaskPriority.p2 => AppTheme.priorityP2,
      TaskPriority.p3 => AppTheme.priorityP3,
      TaskPriority.none => AppTheme.fgMuted,
    };
  }

  Color _priorityActiveBorder(TaskPriority p) {
    return switch (p) {
      TaskPriority.p0 => AppTheme.priorityP0Border,
      TaskPriority.p1 => AppTheme.priorityP1Border,
      TaskPriority.p2 => AppTheme.priorityP2Border,
      TaskPriority.p3 => AppTheme.priorityP3Border,
      TaskPriority.none => AppTheme.borderStrong,
    };
  }

  // ══════════════ 创建按钮 ══════════════

  Widget _buildCreateButton() {
    final enabled = _canSubmit;
    return GestureDetector(
      onTap: enabled ? _submit : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.fg : AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.bg,
                ),
              )
            : Text(
                '创建',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppTheme.bg : AppTheme.fgSubtle,
                ),
              ),
      ),
    );
  }
}
