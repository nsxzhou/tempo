import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/voice_task_parse_result.dart';
import '../domain/task.dart';

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

  bool get _isRecording => _voiceStatus == _VoiceCaptureStatus.recording;
  bool get _isProcessing => _voiceStatus == _VoiceCaptureStatus.processing;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tempo')),
      body: tasks.when(
        data: (items) => _TaskListBody(
          tasks: items,
          voiceStatus: _voiceStatus,
          voiceDraft: _voiceDraft,
          voiceError: _voiceError,
          onCreateDraft: _createDraftTask,
          onDismissDraft: () => setState(() => _voiceDraft = null),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(message: error.toString()),
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

  Future<void> _startVoiceCapture() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _voiceError = null;
      _voiceDraft = null;
    });

    final recorder = ref.read(voiceRecorderProvider);
    final hasPermission = await recorder.hasPermission();
    if (!mounted) {
      return;
    }

    if (!hasPermission) {
      setState(() => _voiceError = '需要麦克风权限才能语音创建任务。');
      return;
    }

    try {
      await recorder.start();
      if (!mounted) {
        return;
      }
      setState(() => _voiceStatus = _VoiceCaptureStatus.recording);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _voiceError = '录音启动失败：$error');
    }
  }

  Future<void> _submitVoiceCapture() async {
    if (!_isRecording) {
      return;
    }

    setState(() => _voiceStatus = _VoiceCaptureStatus.processing);

    try {
      final path = await ref.read(voiceRecorderProvider).stop();
      if (path == null) {
        throw StateError('录音文件为空');
      }

      final result = await ref
          .read(voiceTaskServiceProvider)
          .parseAudioFile(path);

      if (!mounted) {
        return;
      }

      if (result.canAutoCreate) {
        await _createVoiceTask(result);
      } else {
        setState(() {
          _voiceDraft = result;
          _voiceError = null;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _voiceError = '语音创建失败：$error');
    } finally {
      if (mounted) {
        setState(() => _voiceStatus = _VoiceCaptureStatus.idle);
      }
    }
  }

  Future<void> _cancelVoiceCapture() async {
    if (!_isRecording) {
      return;
    }

    await ref.read(voiceRecorderProvider).cancel();
    if (!mounted) {
      return;
    }
    setState(() => _voiceStatus = _VoiceCaptureStatus.idle);
  }

  Future<void> _createDraftTask(String title, String? description) async {
    final draft = _voiceDraft;
    if (draft == null) {
      return;
    }

    setState(() => _voiceDraft = null);
    try {
      await _createVoiceTask(
        draft.copyWith(title: title, description: description),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _voiceError = '语音草稿创建失败：$error');
    }
  }

  Future<void> _createVoiceTask(VoiceTaskParseResult result) async {
    final task = await ref.read(taskRepositoryProvider).createVoiceTask(result);
    if (!mounted) {
      return;
    }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('按住麦克风说出任务，松手后自动创建。')));
  }
}

class _TaskListBody extends StatelessWidget {
  final List<Task> tasks;
  final _VoiceCaptureStatus voiceStatus;
  final VoiceTaskParseResult? voiceDraft;
  final String? voiceError;
  final Future<void> Function(String title, String? description) onCreateDraft;
  final VoidCallback onDismissDraft;

  const _TaskListBody({
    required this.tasks,
    required this.voiceStatus,
    required this.voiceDraft,
    required this.voiceError,
    required this.onCreateDraft,
    required this.onDismissDraft,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _VoiceStatusBanner(status: voiceStatus, error: voiceError),
        if (voiceDraft != null) ...[
          const SizedBox(height: 12),
          _VoiceDraftCard(
            result: voiceDraft!,
            onCreate: onCreateDraft,
            onCancel: onDismissDraft,
          ),
        ],
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const _EmptyTaskState()
        else
          ...tasks.map((task) => _TaskTile(task: task)),
      ],
    );
  }
}

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
      _VoiceCaptureStatus.idle => const _InfoPanel(
        icon: Icons.mic_none,
        color: AppTheme.primaryColor,
        title: '语音创建任务',
        message: '按住右下角麦克风，说出任务、截止时间和优先级。',
      ),
    };
  }
}

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
    _descriptionController = TextEditingController(
      text: widget.result.description ?? '',
    );
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
            Text('需要确认语音任务', style: Theme.of(context).textTheme.titleMedium),
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
                TextButton(onPressed: widget.onCancel, child: const Text('取消')),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.priorityColor(task.priority.value);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withValues(alpha: 0.12),
          foregroundColor: priorityColor,
          child: Text(_priorityShortLabel(task.priority)),
        ),
        title: Text(task.title),
        subtitle: Text(_subtitle),
        trailing: task.creationSource == AppConstants.sourceVoice
            ? const Icon(Icons.mic, size: 20)
            : null,
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (task.dueDate != null) {
      parts.add(DateFormat('M月d日 HH:mm').format(task.dueDate!));
    }
    if (task.description?.isNotEmpty == true) {
      parts.add(task.description!);
    }
    return parts.isEmpty ? '无截止时间' : parts.join(' · ');
  }
}

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 96),
      child: Column(
        children: [
          Icon(Icons.checklist, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('还没有任务', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('按住麦克风快速创建第一条语音任务'),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;

  const _LoadError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('任务加载失败：$message'));
  }
}

String _priorityShortLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.p0 => 'P0',
    TaskPriority.p1 => 'P1',
    TaskPriority.p2 => 'P2',
    TaskPriority.p3 => 'P3',
    TaskPriority.none => '-',
  };
}
