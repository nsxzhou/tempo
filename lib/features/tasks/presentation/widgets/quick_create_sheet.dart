// QuickCreateSheet — 快速创建底部抽屉
// 折叠式:默认只标题+创建按钮;展开后显示日期pills(今天/明天/后天/下周一)+优先级pills(P0~P3)
// 创建后立即关闭 sheet → 后台 Orchestrator 解析+创建 → Snackbar 反馈

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/motion/tempo_sheet.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../data/task_creation_orchestrator.dart';
import '../../data/text_parse_service.dart';
import '../../data/voice_task_parse_result.dart';
import '../../domain/recurrence_models.dart';
import '../../domain/task.dart';
import 'repeat_picker.dart';

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
typedef QuickUpdateCallback =
    Future<Task> Function({
      required Task task,
      required String title,
      DateTime? dueDate,
      required bool isAllDay,
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
    return TempoSheet.show<void>(
      context: context,
      builder: (_) => const QuickCreateSheet(),
    );
  }

  /// 编辑已有任务；成功时返回更新后的 Task
  static Future<Task?> showEdit(
    BuildContext context, {
    required Task task,
    required QuickUpdateCallback onUpdate,
  }) {
    return TempoSheet.show<Task?>(
      context: context,
      builder: (_) => QuickCreateSheet(initialTask: task, onUpdate: onUpdate),
    );
  }

  /// 语音低置信度草稿：预填解析结果供用户确认。
  static Future<void> showPrefill(
    BuildContext context, {
    required VoiceTaskParseResult draft,
  }) {
    return TempoSheet.show<void>(
      context: context,
      builder: (_) => QuickCreateSheet(voiceDraft: draft),
    );
  }

  @override
  ConsumerState<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends ConsumerState<QuickCreateSheet> {
  TempoTokens get t => context.tokens;

  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  late final TextParseService _textParseService;

  bool _expanded = false;
  _QuickDate? _selectedDate;
  DateTime? _customDate;
  TimeOfDay? _selectedTime;
  bool _isAllDay = true;
  TaskPriority _selectedPriority = TaskPriority.none;
  String? _selectedTag;
  bool _tagTouched = false;
  bool _dateTouched = false;
  bool _priorityTouched = false;
  bool _repeatEnabled = false;
  RecurrenceConfig _recurrenceConfig = const RecurrenceConfig(
    interval: 1,
    unit: RecurrenceUnit.day,
  );

  bool _isSubmitting = false;

  bool get _isEditMode => widget.isEditMode;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && !_isSubmitting;

  bool get _skipParse =>
      _dateTouched ||
      _priorityTouched ||
      _tagTouched ||
      widget.isVoicePrefillMode;

  @override
  void initState() {
    super.initState();
    _textParseService = ref.read(textParseServiceProvider);
    final initialTask = widget.initialTask;
    final voiceDraft = widget.voiceDraft;
    if (initialTask != null) {
      _titleController.text = initialTask.title;
      if (initialTask.dueDate != null) {
        final due = initialTask.dueDate!;
        _customDate = DateTime(due.year, due.month, due.day);
        _isAllDay = initialTask.isAllDay;
        if (!initialTask.isAllDay) {
          _selectedTime = TimeOfDay(hour: due.hour, minute: due.minute);
        }
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
      _expanded =
          initialTask.dueDate != null ||
          initialTask.priority != TaskPriority.none ||
          initialTask.tag != null ||
          initialTask.isRecurring;
      if (initialTask.isRecurring) {
        _repeatEnabled = true;
        _recurrenceConfig =
            RecurrenceConfig.fromRRule(initialTask.recurrenceRule) ??
            const RecurrenceConfig(interval: 1, unit: RecurrenceUnit.day);
      }
    } else if (voiceDraft != null) {
      _titleController.text = voiceDraft.title;
      if (voiceDraft.dueDate != null) {
        final due = voiceDraft.dueDate!;
        _customDate = DateTime(due.year, due.month, due.day);
        _isAllDay = voiceDraft.isAllDay;
        if (!voiceDraft.isAllDay) {
          _selectedTime = TimeOfDay(hour: due.hour, minute: due.minute);
        }
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
      _expanded =
          voiceDraft.dueDate != null ||
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
    _preparseTitleIfAllowed();
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _textParseService.cancelPendingParse();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _preparseTitleIfAllowed() {
    if (_isEditMode || widget.isVoicePrefillMode || _skipParse) {
      _textParseService.cancelPendingParse();
      return;
    }
    _textParseService.parseTextDebounced(_titleController.text);
  }

  void _cancelPreparseForManualOverride() {
    if (_isEditMode || widget.isVoicePrefillMode) return;
    _textParseService.cancelPendingParse();
  }

  /// 获取选中的日期部分（不含时间）
  DateTime? get _selectedDatePart {
    if (_customDate != null) {
      return DateTime(_customDate!.year, _customDate!.month, _customDate!.day);
    }
    return _selectedDate?.toDateTime();
  }

  /// 获取最终 dueDate（日期 + 可选时间）
  DateTime? get _effectiveDueDate {
    final date = _selectedDatePart;
    if (date == null) return null;
    if (_isAllDay || _selectedTime == null) {
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  bool get _effectiveIsAllDay {
    if (_effectiveDueDate == null) return false;
    return _isAllDay || _selectedTime == null;
  }

  bool get _hasDate => _selectedDatePart != null;

  void _clearDateTimeState() {
    _selectedTime = null;
    _isAllDay = true;
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
          isAllDay: _effectiveIsAllDay,
          priority: _selectedPriority,
          tag: _selectedTag,
        );
        if (!mounted) return;
        Navigator.of(context).pop(task);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        TempoSnackbar.show(context, message: '保存失败: $e');
      }
      return;
    }

    if (widget.isVoicePrefillMode) {
      final draft = widget.voiceDraft!;
      unawaited(
        ref
            .read(taskCreationOrchestratorProvider)
            .enqueueVoiceCreate(
              draft.copyWith(
                title: title,
                dueDate: _effectiveDueDate ?? draft.dueDate,
                isAllDay: _effectiveDueDate != null
                    ? _effectiveIsAllDay
                    : draft.isAllDay,
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
      ref
          .read(taskCreationOrchestratorProvider)
          .enqueueQuickCreate(
            QuickCreateInput(
              title: title,
              dueDate: _effectiveDueDate,
              isAllDay: _effectiveIsAllDay,
              priority: _selectedPriority,
              tag: _selectedTag,
              skipParse: _skipParse,
              recurrenceRule: _repeatEnabled && _recurrenceConfig.hasRecurrence
                  ? _recurrenceConfig.toRRule()
                  : null,
              recurrenceEnd: _repeatEnabled ? _recurrenceConfig.endDate : null,
              recurrenceCount: _repeatEnabled
                  ? _recurrenceConfig.occurrenceCount
                  : null,
            ),
          ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: [
          const BoxShadow(
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
                    color: t.borderStrong,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.isVoicePrefillMode) ...[
                Text(
                  '确认语音任务',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.fg,
                    letterSpacing: -0.2,
                  ),
                ),
                if (widget.voiceDraft!.rawTranscript.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.voiceDraft!.rawTranscript,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.fgSecondary,
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
                  duration: AppTheme.durationMedium,
                  curve: AppTheme.curveOrganic,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 14),
                            _buildDateSection(),
                            const SizedBox(height: 10),
                            _buildTimeSection(),
                            const SizedBox(height: 14),
                            _buildTagSection(),
                            const SizedBox(height: 14),
                            _buildPrioritySection(),
                            const SizedBox(height: 14),
                            _buildRepeatSection(),
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
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocus,
      maxLines: 1,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.fg),
      decoration: InputDecoration(
        hintText: _isEditMode ? '编辑待办…' : '拟定待办…',
        hintStyle: TextStyle(color: t.fgSubtle, fontSize: 14),
        filled: true,
        fillColor: t.bgSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: t.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: t.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: t.fg, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        suffixIcon: _titleController.text.isNotEmpty
            ? IconButton(
                icon: Icon(LucideIcons.x, size: 14, color: t.fgSubtle),
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
            child: Icon(LucideIcons.chevron_right, size: 14, color: t.fgMuted),
          ),
          const SizedBox(width: 6),
          Text(
            _expanded ? '更多选项' : '更多选项',
            style: AppTheme.mono(
              size: 11,
              color: t.fgMuted,
              letterSpacing: 0.4,
            ),
          ),
          if (_effectiveDueDate != null ||
              _selectedPriority != TaskPriority.none ||
              _selectedTag != null ||
              _repeatEnabled) ...[
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: t.fg, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '重复',
              style: AppTheme.mono(
                size: 10,
                weight: FontWeight.w700,
                color: t.fgMuted,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            _buildRepeatTogglePill(),
          ],
        ),
        if (_repeatEnabled) ...[
          const SizedBox(height: 8),
          RepeatPicker(
            config: _recurrenceConfig,
            onChanged: (c) => setState(() => _recurrenceConfig = c),
          ),
        ],
      ],
    );
  }

  Widget _buildRepeatTogglePill() {
    return GestureDetector(
      onTap: () => setState(() {
        _repeatEnabled = !_repeatEnabled;
        if (_repeatEnabled && !_recurrenceConfig.hasRecurrence) {
          _recurrenceConfig = const RecurrenceConfig(
            interval: 1,
            unit: RecurrenceUnit.day,
          );
        }
      }),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _repeatEnabled ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: _repeatEnabled ? t.fg : t.borderStrong,
            width: _repeatEnabled ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _repeatEnabled ? '开' : '关',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _repeatEnabled ? t.bg : t.fgSecondary,
          ),
        ),
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
            color: t.fgMuted,
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
            _clearDateTimeState();
          } else {
            _selectedDate = date;
            _customDate = null;
            _dateTouched = true;
          }
        });
        _cancelPreparseForManualOverride();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? t.fg : t.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          date.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? t.bg : t.fgSecondary,
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
          color: hasCustom ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: hasCustom ? t.fg : t.borderStrong,
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
              color: hasCustom ? t.bg : t.fgSubtle,
            ),
            const SizedBox(width: 4),
            Text(
              hasCustom ? _formatDate(_customDate!) : '自定义',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasCustom ? t.bg : t.fgSecondary,
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
      _cancelPreparseForManualOverride();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ══════════════ 时间 + 全天 ══════════════

  Widget _buildTimeSection() {
    final enabled = _hasDate;
    return Row(
      children: [
        _buildTimePill(enabled: enabled),
        const SizedBox(width: 8),
        _buildAllDayToggle(enabled: enabled),
      ],
    );
  }

  Widget _buildTimePill({required bool enabled}) {
    final hasSpecificTime = enabled && !_isAllDay;
    final isSelected = hasSpecificTime && _selectedTime != null;
    final label = isSelected ? _formatTime(_selectedTime!) : '选择时间';

    return GestureDetector(
      onTap: enabled ? _onTimePillTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: hasSpecificTime ? t.fg : t.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clock,
              size: 12,
              color: isSelected ? t.bg : (enabled ? t.fgSubtle : t.fgFaint),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? t.bg
                    : (enabled ? t.fgSecondary : t.fgFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDayToggle({required bool enabled}) {
    return GestureDetector(
      onTap: enabled ? _toggleAllDay : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: enabled && _isAllDay ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: enabled && _isAllDay ? t.fg : t.borderStrong,
            width: enabled && _isAllDay ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '全天',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled && _isAllDay
                ? t.bg
                : (enabled ? t.fgSecondary : t.fgFaint),
          ),
        ),
      ),
    );
  }

  Future<void> _onTimePillTap() async {
    if (_isAllDay) {
      setState(() {
        _isAllDay = false;
        _selectedTime ??= const TimeOfDay(hour: 9, minute: 0);
        _dateTouched = true;
      });
      _cancelPreparseForManualOverride();
    }
    await _pickTime();
  }

  Future<void> _pickTime() async {
    final picked = await TempoTimePicker.show(
      context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _isAllDay = false;
        _dateTouched = true;
      });
      _cancelPreparseForManualOverride();
    }
  }

  void _toggleAllDay() {
    setState(() {
      _isAllDay = true;
      _selectedTime = null;
      _dateTouched = true;
    });
    _cancelPreparseForManualOverride();
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
            color: t.fgMuted,
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
        _cancelPreparseForManualOverride();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? t.fg : t.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? t.bg : t.fgSecondary,
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
            color: t.fgMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final p in [
              TaskPriority.p0,
              TaskPriority.p1,
              TaskPriority.p2,
              TaskPriority.p3,
            ]) ...[
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
    final activeBg = AppTheme.priorityBg(p.value);
    final activeFg = AppTheme.priorityColor(p.value);
    final activeBorder = AppTheme.priorityBorder(p.value);

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
        _cancelPreparseForManualOverride();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? activeBorder : t.borderStrong,
            width: isSelected ? 1 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? activeFg : t.fgSecondary,
          ),
        ),
      ),
    );
  }

  // ══════════════ 创建按钮 ══════════════

  Widget _buildCreateButton() {
    final enabled = _canSubmit;
    return GestureDetector(
      onTap: enabled ? _submit : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? t.fg : t.bgMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: _isSubmitting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.bg),
              )
            : Text(
                _isEditMode ? '保存' : '创建',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? t.bg : t.fgSubtle,
                ),
              ),
      ),
    );
  }
}
