// TaskCreationOrchestrator — 后台任务创建：解析 → 入库 → 提醒 → Snackbar

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tempo/src/tempo_snackbar.dart';
import '../domain/task.dart';
import 'notification_service.dart';
import 'streaming_voice_session.dart';
import 'task_ai_enhancement_state.dart';
import 'task_repository.dart';
import 'text_parse_service.dart';
import 'voice_task_parse_result.dart';

/// 快速创建输入（Sheet 关闭后交给 Orchestrator 处理）。
class QuickCreateInput {
  final String title;
  final DateTime? dueDate;
  final bool isAllDay;
  final TaskPriority priority;
  final String? tag;
  final String? recurrenceRule;
  final DateTime? recurrenceEnd;
  final int? recurrenceCount;
  final int? durationMin;

  /// 用户手动改过日期/优先级/tag 时跳过 LLM，直接用原文标题。
  final bool skipParse;

  const QuickCreateInput({
    required this.title,
    this.dueDate,
    this.isAllDay = false,
    this.priority = TaskPriority.none,
    this.tag,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.recurrenceCount,
    this.durationMin,
    this.skipParse = false,
  });
}

typedef TaskCreationSnackbar =
    void Function({
      required String message,
      String? undoLabel,
      Future<void> Function()? onUndo,
    });

typedef VoiceDraftConfirmCallback = void Function(VoiceTaskParseResult draft);

/// 后台执行任务解析、创建与提醒调度，并通过 Snackbar 反馈结果。
class TaskCreationOrchestrator {
  final TaskRepository _repository;
  final TextParseService _parseService;
  final NotificationService _notificationService;
  final TaskCreationSnackbar _showSnackbar;
  final TaskAiEnhancementTracker? _aiEnhancementTracker;

  TaskCreationOrchestrator({
    required TaskRepository repository,
    required TextParseService parseService,
    required NotificationService notificationService,
    required TaskCreationSnackbar showSnackbar,
    TaskAiEnhancementTracker? aiEnhancementTracker,
  }) : _repository = repository,
       _parseService = parseService,
       _notificationService = notificationService,
       _showSnackbar = showSnackbar,
       _aiEnhancementTracker = aiEnhancementTracker;

  /// 快速创建：允许并行；调用方可 fire-and-forget。
  Future<void> enqueueQuickCreate(QuickCreateInput input) {
    return _runQuickCreate(input);
  }

  /// 语音创建：允许并行；调用方可 fire-and-forget。
  Future<void> enqueueVoiceCreate(VoiceTaskParseResult result) {
    return _runVoiceCreate(result);
  }

  /// 语音停止后的后台流水线：ASR 收尾 → LLM 解析 → 自动创建或草稿确认。
  Future<void> enqueueVoicePipeline({
    required StreamingVoiceSession session,
    required VoiceDraftConfirmCallback onNeedDraftConfirm,
  }) {
    return _runVoicePipeline(
      session: session,
      onNeedDraftConfirm: onNeedDraftConfirm,
    );
  }

  Future<void> _runVoicePipeline({
    required StreamingVoiceSession session,
    required VoiceDraftConfirmCallback onNeedDraftConfirm,
  }) async {
    final liveTranscript = session.currentTranscript.trim();
    if (liveTranscript.isNotEmpty) {
      try {
        final task = await _createInitialVoiceTask(liveTranscript);
        _markEnhancementPending(task.id);
        _showSuccess(task, voice: true);
        unawaited(
          _finishVoiceAndEnhanceTask(
            session: session,
            task: task,
            fallbackTranscript: liveTranscript,
          ),
        );
      } catch (e) {
        _showFailure(e);
      }
      return;
    }

    try {
      _showSnackbar(message: '正在识别语音…');
      final transcript = await session.stopAndGetTranscript();
      final trimmed = transcript.trim();
      if (trimmed.isEmpty) {
        _showFailure(const StreamingVoiceException('语音识别结果为空，请重试。'));
        return;
      }

      final cached = _parseService.cachedResultFor(trimmed);
      if (cached != null) {
        final normalized = cached.rawTranscript.trim().isEmpty
            ? cached.copyWith(rawTranscript: trimmed)
            : cached;
        if (normalized.canAutoCreate) {
          await _runVoiceCreate(normalized);
          return;
        }
        onNeedDraftConfirm(normalized);
        return;
      }

      final task = await _createInitialVoiceTask(trimmed);
      _markEnhancementPending(task.id);
      _showSuccess(task, voice: true);
      unawaited(
        _enhanceTaskFromText(
          task: task,
          text: trimmed,
          voice: true,
          requireHighConfidence: true,
        ),
      );
    } catch (e) {
      _showFailure(e);
    }
  }

  Future<void> _runQuickCreate(QuickCreateInput input) async {
    try {
      final rawTitle = input.title.trim();
      if (rawTitle.isEmpty) {
        throw ArgumentError('Task title cannot be empty');
      }

      final cached = input.skipParse
          ? null
          : _parseService.cachedResultFor(rawTitle);
      final fields = cached != null
          ? _fieldsFromParsedResult(
              parsed: cached,
              rawTitle: rawTitle,
              fallbackDueDate: input.dueDate,
              fallbackIsAllDay: input.isAllDay,
              fallbackPriority: input.priority,
              fallbackTag: input.tag,
              fallbackRecurrenceRule: input.recurrenceRule,
              fallbackRecurrenceEnd: input.recurrenceEnd,
              fallbackRecurrenceCount: input.recurrenceCount,
              fallbackDurationMin: input.durationMin,
            )
          : (
              title: rawTitle,
              dueDate: input.dueDate,
              isAllDay: input.isAllDay,
              priority: input.priority,
              tag: input.tag,
              recurrenceRule: input.recurrenceRule,
              recurrenceEnd: input.recurrenceEnd,
              recurrenceCount: input.recurrenceCount,
              durationMin: input.durationMin,
            );
      final task = await _repository.createTask(
        title: fields.title,
        dueDate: fields.dueDate,
        isAllDay: fields.isAllDay,
        priority: fields.priority,
        creationSource: AppConstants.sourceText,
        tag: fields.tag,
        recurrenceRule: fields.recurrenceRule,
        recurrenceEnd: fields.recurrenceEnd,
        recurrenceCount: fields.recurrenceCount,
        durationMin: fields.durationMin,
      );
      await _notificationService.scheduleTaskReminder(task);
      _showSuccess(task, voice: false);

      if (!input.skipParse && cached == null) {
        _markEnhancementPending(task.id);
        unawaited(
          _enhanceTaskFromText(
            task: task,
            text: rawTitle,
            voice: false,
            fallbackDueDate: input.dueDate,
            fallbackIsAllDay: input.isAllDay,
            fallbackPriority: input.priority,
            fallbackTag: input.tag,
            fallbackRecurrenceRule: input.recurrenceRule,
            fallbackRecurrenceEnd: input.recurrenceEnd,
            fallbackRecurrenceCount: input.recurrenceCount,
            fallbackDurationMin: input.durationMin,
          ),
        );
      }
    } catch (e) {
      _showFailure(e);
    }
  }

  Future<void> _runVoiceCreate(VoiceTaskParseResult result) async {
    try {
      final task = await _repository.createVoiceTask(result);
      await _notificationService.scheduleTaskReminder(task);
      _showSuccess(task, voice: true);
    } catch (e) {
      _showFailure(e);
    }
  }

  Future<Task> _createInitialVoiceTask(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) {
      throw const StreamingVoiceException('语音识别结果为空，请重试。');
    }
    final task = await _repository.createTask(
      title: trimmed,
      description: '识别内容: $trimmed',
      creationSource: AppConstants.sourceVoice,
    );
    await _notificationService.scheduleTaskReminder(task);
    return task;
  }

  Future<void> _finishVoiceAndEnhanceTask({
    required StreamingVoiceSession session,
    required Task task,
    required String fallbackTranscript,
  }) async {
    try {
      final finalTranscript = (await session.stopAndGetTranscript()).trim();
      final text = finalTranscript.isNotEmpty
          ? finalTranscript
          : fallbackTranscript;
      await _enhanceTaskFromText(
        task: task,
        text: text,
        voice: true,
        requireHighConfidence: true,
      );
    } catch (_) {
      _markEnhancementFailed(task.id);
    }
  }

  ({
    String title,
    DateTime? dueDate,
    bool isAllDay,
    TaskPriority priority,
    String? tag,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    int? recurrenceCount,
    int? durationMin,
  })
  _fieldsFromParsedResult({
    required VoiceTaskParseResult parsed,
    required String rawTitle,
    DateTime? fallbackDueDate,
    required bool fallbackIsAllDay,
    required TaskPriority fallbackPriority,
    String? fallbackTag,
    String? fallbackRecurrenceRule,
    DateTime? fallbackRecurrenceEnd,
    int? fallbackRecurrenceCount,
    int? fallbackDurationMin,
  }) {
    final createTitle = parsed.title.trim().isNotEmpty
        ? parsed.title.trim()
        : rawTitle;
    return (
      title: createTitle,
      dueDate: parsed.dueDate ?? fallbackDueDate,
      isAllDay: parsed.dueDate != null ? parsed.isAllDay : fallbackIsAllDay,
      priority: parsed.priority != TaskPriority.none
          ? parsed.priority
          : fallbackPriority,
      tag: parsed.tag ?? fallbackTag,
      recurrenceRule: parsed.recurrenceRule ?? fallbackRecurrenceRule,
      recurrenceEnd: parsed.recurrenceEnd ?? fallbackRecurrenceEnd,
      recurrenceCount: parsed.recurrenceCount ?? fallbackRecurrenceCount,
      durationMin: parsed.durationMin ?? fallbackDurationMin,
    );
  }

  Future<void> _enhanceTaskFromText({
    required Task task,
    required String text,
    required bool voice,
    bool requireHighConfidence = false,
    DateTime? fallbackDueDate,
    bool fallbackIsAllDay = false,
    TaskPriority fallbackPriority = TaskPriority.none,
    String? fallbackTag,
    String? fallbackRecurrenceRule,
    DateTime? fallbackRecurrenceEnd,
    int? fallbackRecurrenceCount,
    int? fallbackDurationMin,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _markEnhancementFailed(task.id);
      return;
    }

    try {
      final result =
          _parseService.cachedResultFor(trimmed) ??
          await _parseService.parseText(trimmed);
      if (result == null || (requireHighConfidence && !result.canAutoCreate)) {
        _markEnhancementFailed(task.id);
        return;
      }

      final normalized = result.rawTranscript.trim().isEmpty
          ? result.copyWith(rawTranscript: trimmed)
          : result;
      final current = await _repository.getTaskById(task.id);
      if (current == null) {
        _markEnhancementSucceeded(task.id);
        return;
      }
      if (!_canApplyEnhancement(current: current, original: task)) {
        _markEnhancementSucceeded(task.id);
        return;
      }

      final fields = _fieldsFromParsedResult(
        parsed: normalized,
        rawTitle: task.title,
        fallbackDueDate: fallbackDueDate ?? task.dueDate,
        fallbackIsAllDay: fallbackIsAllDay || task.isAllDay,
        fallbackPriority: fallbackPriority != TaskPriority.none
            ? fallbackPriority
            : task.priority,
        fallbackTag: fallbackTag ?? task.tag,
        fallbackRecurrenceRule: fallbackRecurrenceRule ?? task.recurrenceRule,
        fallbackRecurrenceEnd: fallbackRecurrenceEnd ?? task.recurrenceEnd,
        fallbackRecurrenceCount:
            fallbackRecurrenceCount ?? task.recurrenceCount,
        fallbackDurationMin: fallbackDurationMin ?? task.durationMin,
      );
      final updated = current.copyWith(
        title: fields.title,
        description: voice
            ? _voiceDescription(normalized)
            : current.description,
        dueDate: fields.dueDate,
        isAllDay: fields.isAllDay,
        priority: fields.priority,
        tag: fields.tag,
        recurrenceRule: fields.recurrenceRule,
        recurrenceEnd: fields.recurrenceEnd,
        recurrenceCount: fields.recurrenceCount,
        durationMin: fields.durationMin,
      );

      await _repository.updateTask(updated);
      await _notificationService.scheduleTaskReminder(updated);
      _markEnhancementSucceeded(task.id);
    } catch (_) {
      _markEnhancementFailed(task.id);
    }
  }

  String _voiceDescription(VoiceTaskParseResult result) {
    final description = result.description?.trim();
    if (description != null && description.isNotEmpty) return description;
    return '识别内容: ${result.rawTranscript}';
  }

  bool _canApplyEnhancement({required Task current, required Task original}) {
    return current.title == original.title &&
        current.description == original.description &&
        current.dueDate == original.dueDate &&
        current.isAllDay == original.isAllDay &&
        current.priority == original.priority &&
        current.tag == original.tag &&
        current.recurrenceRule == original.recurrenceRule &&
        current.recurrenceEnd == original.recurrenceEnd &&
        current.recurrenceCount == original.recurrenceCount &&
        current.durationMin == original.durationMin;
  }

  void _markEnhancementPending(String taskId) {
    _aiEnhancementTracker?.markPending(taskId);
  }

  void _markEnhancementSucceeded(String taskId) {
    _aiEnhancementTracker?.markSucceeded(taskId);
  }

  void _markEnhancementFailed(String taskId) {
    _aiEnhancementTracker?.markFailed(taskId);
  }

  void _showSuccess(Task task, {required bool voice}) {
    final prefix = voice ? '已创建语音任务' : '已创建';
    _showSnackbar(
      message: '$prefix:${task.title}',
      undoLabel: '撤回',
      onUndo: () async {
        await _repository.deleteTask(task.id);
        await _notificationService.cancelTaskReminders(task.id);
      },
    );
  }

  void _showFailure(Object error) {
    _showSnackbar(message: '创建失败:$error');
  }
}

/// 使用全局 Navigator Overlay 显示 Toast（无局部 BuildContext 时）。
TaskCreationSnackbar createGlobalSnackbar({
  required GlobalKey<NavigatorState> navigatorKey,
}) {
  return ({
    required String message,
    String? undoLabel,
    Future<void> Function()? onUndo,
  }) {
    TempoSnackbar.showGlobal(
      navigatorKey: navigatorKey,
      message: message,
      undoLabel: undoLabel,
      onUndo: onUndo,
    );
  };
}
