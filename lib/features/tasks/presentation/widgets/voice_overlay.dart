// VoiceOverlay — 语音录入底部抽屉(对应 prototype VoiceOverlay.tsx)
// 黑色半透遮罩 + 白色圆角抽屉 + 麦克风脉冲 + 转写 + 低置信度草稿确认
// 交互:tap 麦克风开始 → tap 停止 → 自动解析 → 高置信度自动创建 / 低置信度草稿确认

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../data/voice_task_parse_result.dart';
import '../../domain/task.dart';

enum _VoicePhase { idle, recording, processing, draft }

class VoiceOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function(VoiceTaskParseResult result) onAutoCreate;

  const VoiceOverlay({
    super.key,
    required this.onClose,
    required this.onAutoCreate,
  });

  @override
  ConsumerState<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends ConsumerState<VoiceOverlay>
    with SingleTickerProviderStateMixin {
  _VoicePhase _phase = _VoicePhase.idle;
  String? _error;
  VoiceTaskParseResult? _draft;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _isRecording => _phase == _VoicePhase.recording;

  Future<void> _toggleRecording() async {
    if (_phase == _VoicePhase.recording) {
      await _stopAndParse();
    } else if (_phase == _VoicePhase.idle) {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final recorder = ref.read(voiceRecorderProvider);
    final hasPermission = await recorder.hasPermission();
    if (!mounted) return;
    if (!hasPermission) {
      setState(() => _error = '需要麦克风权限才能语音创建任务。');
      return;
    }
    try {
      await recorder.start();
      if (!mounted) return;
      setState(() => _phase = _VoicePhase.recording);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '录音启动失败:$e');
    }
  }

  Future<void> _stopAndParse() async {
    setState(() => _phase = _VoicePhase.processing);
    try {
      final path = await ref.read(voiceRecorderProvider).stop();
      if (path == null) throw StateError('录音文件为空');
      final result =
          await ref.read(voiceTaskServiceProvider).parseAudioFile(path);
      if (!mounted) return;
      if (result.canAutoCreate) {
        await widget.onAutoCreate(result);
        widget.onClose();
      } else {
        setState(() {
          _draft = result;
          _titleController.text = result.title;
          _descController.text = result.description ?? '';
          _phase = _VoicePhase.draft;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '语音创建失败:$e';
        _phase = _VoicePhase.idle;
      });
    }
  }

  Future<void> _confirmDraft() async {
    final draft = _draft;
    if (draft == null) return;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final edited = draft.copyWith(
      title: title.isEmpty ? draft.title : title,
      description: desc.isEmpty ? null : desc,
    );
    await widget.onAutoCreate(edited);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: const Color(0x73000000), // black/45
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: _buildSheet(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (_error != null) ...[
            _buildErrorBar(),
            const SizedBox(height: 12),
          ],
          if (_phase == _VoicePhase.draft) _buildDraftMode()
          else _buildRecordMode(),
        ],
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.priorityP0Bg,
        border: Border.all(color: AppTheme.priorityP0Border, width: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circle_alert, size: 14, color: AppTheme.priorityP0),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 11, color: AppTheme.priorityP0, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgSubtle,
            border: Border.all(color: AppTheme.borderStrong, width: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              _buildMicButton(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gemini Whisper V2 Engine',
                      style: AppTheme.mono(size: 10, color: AppTheme.fgSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildMicButton() {
    final recording = _isRecording;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (recording)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Transform.scale(
                  scale: 1.0 + t * 0.5,
                  child: Opacity(
                    opacity: (1 - t) * 0.85,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.fg, width: 1),
                      ),
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            key: const ValueKey('voice-mic'),
            onTap: _phase == _VoicePhase.processing ? null : _toggleRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: recording ? AppTheme.fg : AppTheme.bgMuted,
                shape: BoxShape.circle,
                border: recording
                    ? null
                    : Border.all(color: AppTheme.borderStrong, width: 0.8),
              ),
              alignment: Alignment.center,
              child: _phase == _VoicePhase.processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.bg,
                      ),
                    )
                  : Icon(
                      recording ? LucideIcons.square : LucideIcons.mic,
                      size: 18,
                      color: recording ? AppTheme.bg : AppTheme.fg,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    switch (_phase) {
      case _VoicePhase.recording:
        return '语音采音中 · 点击麦克风停止';
      case _VoicePhase.processing:
        return '正在解析语音…';
      default:
        return '点击麦克风开始采音';
    }
  }

  Widget _buildDraftMode() {
    final draft = _draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '需要确认语音任务',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.fg,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '置信度低于阈值,请确认后创建',
          style: AppTheme.mono(size: 10, color: AppTheme.fgMuted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _titleController,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.fg,
          ),
          decoration: InputDecoration(
            hintText: '任务标题',
            hintStyle: TextStyle(color: AppTheme.fgSubtle),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.fgSecondary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: '描述(可选)',
            hintStyle: TextStyle(color: AppTheme.fgSubtle),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        if (draft != null) ...[
          const SizedBox(height: 12),
          _buildNlpTags(draft),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCancelButton()),
            const SizedBox(width: 10),
            Expanded(child: _buildCreateButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildNlpTags(VoiceTaskParseResult draft) {
    final tags = <Widget>[];
    if (draft.dueDate != null) {
      tags.add(
        TempoPillBadge(
          label: DateFormat('MM/dd HH:mm').format(draft.dueDate!),
          kind: TempoBadgeKind.tag,
          icon: LucideIcons.calendar,
          fontSize: 10,
        ),
      );
    }
    tags.add(
      TempoPillBadge(
        label: _priorityLabel(draft.priority),
        kind: _priorityKind(draft.priority),
        icon: LucideIcons.flag,
        fontSize: 10,
      ),
    );
    return Wrap(spacing: 6, runSpacing: 6, children: tags);
  }

  String _priorityLabel(TaskPriority p) {
    return switch (p) {
      TaskPriority.p0 => 'P0 紧急',
      TaskPriority.p1 => 'P1 高',
      TaskPriority.p2 => 'P2 中',
      TaskPriority.p3 => 'P3 低',
      TaskPriority.none => '无优先级',
    };
  }

  TempoBadgeKind _priorityKind(TaskPriority p) {
    return switch (p) {
      TaskPriority.p0 => TempoBadgeKind.p0,
      TaskPriority.p1 => TempoBadgeKind.p1,
      TaskPriority.p2 => TempoBadgeKind.p2,
      TaskPriority.p3 => TempoBadgeKind.p3,
      TaskPriority.none => TempoBadgeKind.neutral,
    };
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border.all(color: AppTheme.borderStrong, width: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: const Text(
          '取消',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.fgMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _confirmDraft,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.fg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: const Text(
          '创建任务',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.bg,
          ),
        ),
      ),
    );
  }
}
