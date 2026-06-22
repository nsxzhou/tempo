// TaskCreationOrchestrator — 后台任务创建：解析 → 入库 → 提醒 → Snackbar

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tempo/src/tempo_snackbar.dart';
import '../domain/task.dart';
import 'notification_service.dart';
import 'streaming_voice_session.dart';
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

  /// 用户手动改过日期/优先级/tag 时跳过 LLM，直接用原文标题。
  final bool skipParse;

  const QuickCreateInput({
    required this.title,
    this.dueDate,
    this.isAllDay = false,
    this.priority = TaskPriority.none,
    this.tag,
    this.skipParse = false,
  });
}

typedef TaskCreationSnackbar = void Function({
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

  TaskCreationOrchestrator({
    required TaskRepository repository,
    required TextParseService parseService,
    required NotificationService notificationService,
    required TaskCreationSnackbar showSnackbar,
  })  : _repository = repository,
        _parseService = parseService,
        _notificationService = notificationService,
        _showSnackbar = showSnackbar;

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
    try {
      final transcript = await session.stopAndGetTranscript();
      final trimmed = transcript.trim();
      if (trimmed.isEmpty) {
        _showFailure(const StreamingVoiceException('语音识别结果为空，请重试。'));
        return;
      }

      final cached = _parseService.cachedResultFor(trimmed);
      final result = cached ?? await _parseService.parseText(trimmed);
      if (result == null) {
        _showFailure(const StreamingVoiceException('任务理解失败，请重试。'));
        return;
      }

      final normalized = result.rawTranscript.trim().isEmpty
          ? result.copyWith(rawTranscript: trimmed)
          : result;

      if (normalized.canAutoCreate) {
        await _runVoiceCreate(normalized);
        return;
      }

      onNeedDraftConfirm(normalized);
    } catch (e) {
      _showFailure(e);
    }
  }

  Future<void> _runQuickCreate(QuickCreateInput input) async {
    try {
      final fields = await _resolveQuickCreateFields(input);
      final task = await _repository.createTask(
        title: fields.title,
        dueDate: fields.dueDate,
        isAllDay: fields.isAllDay,
        priority: fields.priority,
        creationSource: AppConstants.sourceText,
        tag: fields.tag,
      );
      await _notificationService.scheduleTaskReminder(task);
      _showSuccess(task, voice: false);
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

  Future<({
    String title,
    DateTime? dueDate,
    bool isAllDay,
    TaskPriority priority,
    String? tag,
  })> _resolveQuickCreateFields(QuickCreateInput input) async {
    final rawTitle = input.title.trim();
    if (rawTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    if (input.skipParse) {
      return (
        title: rawTitle,
        dueDate: input.dueDate,
        isAllDay: input.isAllDay,
        priority: input.priority,
        tag: input.tag,
      );
    }

    final cached = _parseService.cachedResultFor(rawTitle);
    final parsed = cached ?? await _parseService.parseText(rawTitle);
    if (parsed == null) {
      return (
        title: rawTitle,
        dueDate: input.dueDate,
        isAllDay: input.isAllDay,
        priority: input.priority,
        tag: input.tag,
      );
    }

    final createTitle =
        parsed.title.trim().isNotEmpty ? parsed.title.trim() : rawTitle;
    return (
      title: createTitle,
      dueDate: parsed.dueDate ?? input.dueDate,
      isAllDay: parsed.dueDate != null ? parsed.isAllDay : input.isAllDay,
      priority: parsed.priority != TaskPriority.none
          ? parsed.priority
          : input.priority,
      tag: parsed.tag ?? input.tag,
    );
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
