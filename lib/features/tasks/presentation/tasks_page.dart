// ============================================================
// TasksPage — 任务列表页（Phase 1 核心页面）
// 顶部 inline 输入框 + Checkbox 切换 + 左滑删除 + 语音 FAB
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/voice_task_parse_result.dart';
import '../domain/task.dart';
import 'widgets/inline_task_input.dart';
import 'widgets/task_tile.dart';

enum _VoiceCaptureStatus { idle, recording, processing }

/// 任务列表页（Phase 1 核心页面）
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  _VoiceCaptureStatus _voiceStatus = _VoiceCaptureStatus.idle;
  VoiceTaskParseResult? _voiceDraft;
  String? _voiceError;
  Task? _lastDeletedTask;

  bool get _isRecording => _voiceStatus == _VoiceCaptureStatus.recording;
  bool get _isProcessing => _voiceStatus == _VoiceCaptureStatus.processing;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tempo')),
      body: Column(
        children: [
          // inline 输入框
          InlineTaskInput(
            onTaskCreated: (task) {
              if (task != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 3),
                    content: Text('已创建：${task.title}'),
                    action: SnackBarAction(
                      label: '撤回',
                      onPressed: () {
                        unawaited(
                          ref.read(taskRepositoryProvider).deleteTask(task.id),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
          // 语音状态 Banner
          if (_voiceStatus != _VoiceCaptureStatus.idle || _voiceError != null)
            _VoiceStatusBanner(status: _voiceStatus, error: _voiceError),
          // 语音草稿卡片
          if (_voiceDraft != null)
            _VoiceDraftCard(
              result: _voiceDraft!,
              onCreate: _createDraftTask,
              onCancel: () => setState(() => _voiceDraft = null),
            ),
          const SizedBox(height: 4),
          // 任务列表
          Expanded(
            child: tasks.when(
              data: (items) => _TaskListBody(
                tasks: items,
                onToggle: _toggleTask,
                onTap: _navigateToDetail,
                onDelete: _deleteTask,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('加载失败：$error')),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        key: const ValueKey('voice-fab'),
        onLongPressStart: (_) => unawaited(_startVoiceCapture()),
        onLongPressEnd: (_) => unawaited(_submitVoiceCapture()),
        onLongPressCancel: () => unawaited(_cancelVoiceCapture()),
        child: FloatingActionButton.extended(
          onPressed: _showVoiceHint,
          icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
          label: Text(_voiceButtonLabel),
        ),
      ),
    );
  }

  String get _voiceButtonLabel {
    return switch (_voiceStatus) {
      _VoiceCaptureStatus.recording => '松手创建',
      _VoiceCaptureStatus.processing => '识别中',
      _VoiceCaptureStatus.idle => '按住说话',
    };
  }

  /// 切换任务完成状态。
  Future<void> _toggleTask(Task task) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final updated = await repository.toggleComplete(task.id);

      // 完成时取消通知，取消完成时重新调度
      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        await notificationService.cancelTaskReminders(task.id);
      } else {
        await notificationService.scheduleTaskReminder(updated);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$error')),
      );
    }
  }

  /// 跳转到任务详情页。
  void _navigateToDetail(Task task) {
    context.push('/tasks/${task.id}');
  }

  /// 删除任务（带撤回）。
  Future<void> _deleteTask(Task task) async {
    _lastDeletedTask = task;
    try {
      await ref.read(taskRepositoryProvider).deleteTask(task.id);

      // 取消通知
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelTaskReminders(task.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('已删除：${task.title}'),
          action: SnackBarAction(
            label: '撤回',
            onPressed: () {
              if (_lastDeletedTask != null) {
                unawaited(
                  ref.read(taskRepositoryProvider).createTask(
                        title: _lastDeletedTask!.title,
                        description: _lastDeletedTask!.description,
                        dueDate: _lastDeletedTask!.dueDate,
                        priority: _lastDeletedTask!.priority,
                        creationSource: _lastDeletedTask!.creationSource,
                      ),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error')),
      );
    }
  }

  // ── 语音录制逻辑 ──

  Future<void> _startVoiceCapture() async {
    if (_isProcessing) return;

    setState(() {
      _voiceError = null;
      _voiceDraft = null;
    });

    final recorder = ref.read(voiceRecorderProvider);
    final hasPermission = await recorder.hasPermission();
    if (!mounted) return;

    if (!hasPermission) {
      setState(() => _voiceError = '需要麦克风权限才能语音创建任务。');
      return;
    }

    try {
      await recorder.start();
      if (!mounted) return;
      setState(() => _voiceStatus = _VoiceCaptureStatus.recording);
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceError = '录音启动失败：$error');
    }
  }

  Future<void> _submitVoiceCapture() async {
    if (!_isRecording) return;

    setState(() => _voiceStatus = _VoiceCaptureStatus.processing);

    try {
      final path = await ref.read(voiceRecorderProvider).stop();
      if (path == null) throw StateError('录音文件为空');

      final result =
          await ref.read(voiceTaskServiceProvider).parseAudioFile(path);

      if (!mounted) return;

      if (result.canAutoCreate) {
        await _createVoiceTask(result);
      } else {
        setState(() {
          _voiceDraft = result;
          _voiceError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceError = '语音创建失败：$error');
    } finally {
      if (mounted) {
        setState(() => _voiceStatus = _VoiceCaptureStatus.idle);
      }
    }
  }

  Future<void> _cancelVoiceCapture() async {
    if (!_isRecording) return;
    await ref.read(voiceRecorderProvider).cancel();
    if (!mounted) return;
    setState(() => _voiceStatus = _VoiceCaptureStatus.idle);
  }

  Future<void> _createDraftTask(String title, String? description) async {
    final draft = _voiceDraft;
    if (draft == null) return;

    setState(() => _voiceDraft = null);
    try {
      await _createVoiceTask(
        draft.copyWith(title: title, description: description),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceError = '语音草稿创建失败：$error');
    }
  }

  Future<void> _createVoiceTask(VoiceTaskParseResult result) async {
    final task = await ref.read(taskRepositoryProvider).createVoiceTask(result);
    if (!mounted) return;

    // 调度通知
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleTaskReminder(task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('已创建语音任务：${task.title}'),
        action: SnackBarAction(
          label: '撤回',
          onPressed: () {
            unawaited(ref.read(taskRepositoryProvider).deleteTask(task.id));
          },
        ),
      ),
    );
  }

  void _showVoiceHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('按住麦克风说出任务，松手后自动创建。')),
    );
  }
}

/// 任务列表主体。
class _TaskListBody extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(Task) onTap;
  final void Function(Task) onDelete;

  const _TaskListBody({
    required this.tasks,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_rounded,
        title: '还没有任务',
        subtitle: '在顶部输入框输入任务标题，回车快速创建\n或按住右下角麦克风语音创建',
      );
    }

    // 按完成状态分组
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        ...activeTasks.map((task) => TaskTile(
              task: task,
              onToggleComplete: () => onToggle(task),
              onTap: () => onTap(task),
              onDelete: () => onDelete(task),
            )),
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '已完成 (${completedTasks.length})',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...completedTasks.map((task) => TaskTile(
                task: task,
                onToggleComplete: () => onToggle(task),
                onTap: () => onTap(task),
                onDelete: () => onDelete(task),
              )),
        ],
      ],
    );
  }
}

/// 语音状态 Banner。
class _VoiceStatusBanner extends StatelessWidget {
  final _VoiceCaptureStatus status;
  final String? error;

  const _VoiceStatusBanner({required this.status, required this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _InfoPanel(
        icon: Icons.error_outline,
        color: AppTheme.errorColor,
        title: '语音创建失败',
        message: error!,
      );
    }

    return switch (status) {
      _VoiceCaptureStatus.recording => const _InfoPanel(
          icon: Icons.mic,
          color: AppTheme.errorColor,
          title: '录音中',
          message: '松手后提交语音，滑开或取消可放弃本次录音。',
        ),
      _VoiceCaptureStatus.processing => const _InfoPanel(
          icon: Icons.auto_awesome,
          color: AppTheme.primaryColor,
          title: '识别中',
          message: '正在通过后端代理识别语音并解析任务。',
        ),
      _VoiceCaptureStatus.idle => const SizedBox.shrink(),
    };
  }
}

/// 语音草稿确认卡片。
class _VoiceDraftCard extends StatefulWidget {
  final VoiceTaskParseResult result;
  final Future<void> Function(String title, String? description) onCreate;
  final VoidCallback onCancel;

  const _VoiceDraftCard({
    required this.result,
    required this.onCreate,
    required this.onCancel,
  });

  @override
  State<_VoiceDraftCard> createState() => _VoiceDraftCardState();
}

class _VoiceDraftCardState extends State<_VoiceDraftCard> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.result.title);
    _descriptionController =
        TextEditingController(text: widget.result.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('voice-draft-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('需要确认语音任务',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '置信度 ${(widget.result.confidence * 100).round()}%，先确认再创建。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '任务标题'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '描述'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                    onPressed: widget.onCancel, child: const Text('取消')),
                FilledButton(
                  onPressed: () => unawaited(
                    widget.onCreate(
                      _titleController.text,
                      _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text,
                    ),
                  ),
                  child: const Text('创建任务'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 信息面板。
class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _InfoPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
