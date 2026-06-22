// QuickCreateSheet — 快速创建底部抽屉
// 折叠式:默认只标题+创建按钮;展开后显示日期pills(今天/明天/后天/下周一)+优先级pills(P0~P3)
// 创建后立即关闭 sheet → 后台 Orchestrator 解析+创建 → Snackbar 反馈

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tempo/src/tempo_date_picker.dart';
import '../../../../core/widgets/tempo/src/tempo_snackbar.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../data/task_creation_orchestrator.dart';
import '../../data/voice_task_parse_result.dart';
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

/// 快速编辑回调：返回更新后的 Task
typedef QuickUpdateCallback = Future<Task> Function({
  required Task task,
  required String title,
  DateTime? dueDate,
  TaskPriority priority,
  String? tag,
});

class QuickCreateSheet extends ConsumerStatefulWidget {
  final QuickUpdateCallback? onUpdate;
  final Task? initialTask;
  final VoiceTaskParseResult? voiceDraft;

  const QuickCreateSheet({
    super.key,
    this.onUpdate,
    this.initialTask,
    this.voiceDraft,
  }) : assert(
          onUpdate != null || initialTask == null,
          'Provide onUpdate + initialTask for edit mode',
        );

  bool get isEditMode => initialTask != null;

  bool get isVoicePrefillMode => voiceDraft != null;

  /// 从 TasksPage 弹出快速创建 bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000), // 和 VoiceOverlay 一致 black/45
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => const QuickCreateSheet(),
    );
  }

  /// 编辑已有任务；成功时返回更新后的 Task
  static Future<Task?> showEdit(
    BuildContext context, {
    required Task task,
    required QuickUpdateCallback onUpdate,
  }) {
    return showModalBottomSheet<Task?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => QuickCreateSheet(
        initialTask: task,
        onUpdate: onUpdate,
      ),
    );
  }

  /// 语音低置信度草稿：预填解析结果供用户确认。
  static Future<void> showPrefill(
    BuildContext context, {
    required VoiceTaskParseResult draft,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => QuickCreateSheet(voiceDraft: draft),
    );
  }

  @override
  ConsumerState<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends ConsumerState<QuickCreateSheet> {
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();

  bool _expanded = false;
  _QuickDate? _selectedDate;
  DateTime? _customDate;
  TaskPriority _selectedPriority = TaskPriority.none;
  String? _selectedTag;
  bool _tagTouched = false;
  bool _dateTouched = false;
  bool _priorityTouched = false;

  bool _isSubmitting = false;

  bool get _isEditMode => widget.isEditMode;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && !_isSubmitting;

  bool get _skipParse =>
      _dateTouched || _priorityTouched || _tagTouched || widget.isVoicePrefillMode;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    final voiceDraft = widget.voiceDraft;
    if (initialTask != null) {
      _titleController.text = initialTask.title;
      if (initialTask.dueDate != null) {
        _customDate = initialTask.dueDate;
        _dateTouched = true;
      }
      if (initialTask.priority != TaskPriority.none) {
        _selectedPriority = initialTask.priority;
        _priorityTouched = true;
      }
      if (initialTask.tag != null) {
        _selectedTag = initialTask.tag;
        _tagTouched = true;
      }
      _expanded = initialTask.dueDate != null ||
          initialTask.priority != TaskPriority.none ||
          initialTask.tag != null;
    } else if (voiceDraft != null) {
      _titleController.text = voiceDraft.title;
      if (voiceDraft.dueDate != null) {
        _customDate = voiceDraft.dueDate;
        _dateTouched = true;
      }
      if (voiceDraft.priority != TaskPriority.none) {
        _selectedPriority = voiceDraft.priority;
        _priorityTouched = true;
      }
      if (voiceDraft.tag != null) {
        _selectedTag = voiceDraft.tag;
        _tagTouched = true;
      }
      _expanded = voiceDraft.dueDate != null ||
          voiceDraft.priority != TaskPriority.none ||
          voiceDraft.tag != null;
    }
    _titleController.addListener(_onTitleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _titleFocus.requestFocus();
    });
  }

  void _onTitleChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
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

    final title = _titleController.text.trim();

    if (_isEditMode) {
      setState(() => _isSubmitting = true);
      try {
        final task = await widget.onUpdate!(
          task: widget.initialTask!,
          title: title,
          dueDate: _effectiveDueDate,
          priority: _selectedPriority,
          tag: _selectedTag,
        );
        if (!mounted) return;
        Navigator.of(context).pop(task);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        TempoSnackbar.show(
          context,
          message: '保存失败: $e',
        );
      }
      return;
    }

    if (widget.isVoicePrefillMode) {
      final draft = widget.voiceDraft!;
      unawaited(
        ref.read(taskCreationOrchestratorProvider).enqueueVoiceCreate(
              draft.copyWith(
                title: title,
                dueDate: _effectiveDueDate ?? draft.dueDate,
                priority: _selectedPriority,
                tag: _selectedTag ?? draft.tag,
              ),
            ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    unawaited(
      ref.read(taskCreationOrchestratorProvider).enqueueQuickCreate(
            QuickCreateInput(
              title: title,
              dueDate: _effectiveDueDate,
              isAllDay: _effectiveDueDate != null,
              priority: _selectedPriority,
              tag: _selectedTag,
              skipParse: _skipParse,
            ),
          ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
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
          child: SingleChildScrollView(
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
                if (widget.isVoicePrefillMode) ...[
                  const Text(
                    '确认语音任务',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.voiceDraft!.rawTranscript.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.voiceDraft!.rawTranscript,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.fgSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                // 标题输入框
                _buildTitleField(),
                const SizedBox(height: 10),
                // 折叠展开区
                _buildExpandToggle(),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 14),
                              _buildDateSection(),
                              const SizedBox(height: 14),
                              _buildTagSection(),
                              const SizedBox(height: 14),
                              _buildPrioritySection(),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 14),
                // 创建按钮
                _buildCreateButton(),
              ],
            ),
          ),
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
        hintText: _isEditMode ? '编辑待办…' : '拟定待办…',
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
          AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Icon(
              LucideIcons.chevron_right,
              size: 14,
              color: AppTheme.fgMuted,
            ),
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
          if (_effectiveDueDate != null ||
              _selectedPriority != TaskPriority.none ||
              _selectedTag != null) ...[
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
            _selectedDate = null;
          } else {
            _selectedDate = date;
            _customDate = null;
            _dateTouched = true;
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
    final now = DateTime.now();
    final picked = await TempoDatePicker.show(
      context,
      initialDate: _customDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _customDate = DateTime(picked.year, picked.month, picked.day);
        _selectedDate = null;
        _dateTouched = true;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // ══════════════ 分类 pills ══════════════

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类',
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
            _buildTagPill('工作', AppConstants.tagWork),
            const SizedBox(width: 8),
            _buildTagPill('生活', AppConstants.tagLife),
            const SizedBox(width: 8),
            _buildTagPill('未分类', null),
          ],
        ),
      ],
    );
  }

  Widget _buildTagPill(String label, String? value) {
    final isSelected = _selectedTag == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tagTouched = true;
          if (isSelected && value != null) {
            _selectedTag = null;
          } else {
            _selectedTag = value;
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
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.bg : AppTheme.fgSecondary,
          ),
        ),
      ),
    );
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
          _priorityTouched = true;
          if (isSelected) {
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
                _isEditMode ? '保存' : '创建',
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
