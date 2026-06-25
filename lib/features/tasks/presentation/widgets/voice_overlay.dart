// VoiceOverlay — 语音录入底部抽屉
// 流式 ASR 边录边出字 → 停止后立即关层 → 后台 ASR 收尾 + LLM 解析

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../data/streaming_voice_session.dart';
import '../../data/task_creation_orchestrator.dart';
import '../../data/volcengine_streaming_asr.dart';

enum _VoicePhase { idle, recording }

class VoiceOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoiceDraftConfirmCallback onNeedDraftConfirm;

  const VoiceOverlay({
    super.key,
    required this.onClose,
    required this.onNeedDraftConfirm,
  });

  @override
  ConsumerState<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends ConsumerState<VoiceOverlay>
    with TickerProviderStateMixin {
  TempoTokens get tokens => context.tokens;

  static const _transcriptThrottle = Duration(milliseconds: 100);

  _VoicePhase _phase = _VoicePhase.idle;
  String? _error;
  String _transcript = '';
  String _pendingTranscript = '';
  bool _pipelineRunning = false;
  bool _isClosing = false;
  StreamSubscription<String>? _transcriptSub;
  Timer? _transcriptThrottleTimer;
  late final TextEditingController _transcriptController;
  late final AnimationController _pulse;
  late final AnimationController _enterController;
  late final Animation<double> _enterAnimation;
  StreamingVoiceSession? _session;

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _enterController = AnimationController(
      vsync: this,
      duration: AppTheme.durationMedium,
    );
    _enterAnimation = CurvedAnimation(
      parent: _enterController,
      curve: AppTheme.curveOrganic,
      reverseCurve: Curves.easeInCubic,
    );
    _enterController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session = ref.read(streamingVoiceSessionProvider);
      unawaited(_session!.prepare());
    });
  }

  @override
  void dispose() {
    _transcriptSub?.cancel();
    _transcriptThrottleTimer?.cancel();
    _transcriptController.dispose();
    _pulse.dispose();
    _enterController.dispose();
    if (!_pipelineRunning && _phase != _VoicePhase.recording) {
      unawaited(_session?.disposeSession());
    }
    super.dispose();
  }

  bool get _isRecording => _phase == _VoicePhase.recording;

  Future<void> _toggleRecording() async {
    if (_phase == _VoicePhase.recording) {
      await _stopAndPipeline();
    } else if (_phase == _VoicePhase.idle) {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _transcript = '';
      _pendingTranscript = '';
      _transcriptController.clear();
      _phase = _VoicePhase.recording;
    });

    try {
      final session = ref.read(streamingVoiceSessionProvider);
      await session.startRecording();
      if (!mounted) return;

      _transcriptSub?.cancel();
      _transcriptSub = session.transcriptStream.listen(_onTranscriptUpdate);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _formatStartError(e);
        _phase = _VoicePhase.idle;
      });
    }
  }

  void _onTranscriptUpdate(String text) {
    if (!mounted) return;
    _pendingTranscript = text;
    if (_transcriptThrottleTimer?.isActive ?? false) return;

    _applyTranscript(text);
    _transcriptThrottleTimer = Timer(_transcriptThrottle, () {
      if (!mounted) return;
      if (_pendingTranscript != _transcript) {
        _applyTranscript(_pendingTranscript);
      }
    });

    ref.read(textParseServiceProvider).parseTextDebounced(text);
  }

  void _applyTranscript(String text) {
    _transcript = text;
    _transcriptController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _animateClose(VoidCallback afterClose) async {
    if (_isClosing) return;
    _isClosing = true;
    await _enterController.reverse();
    if (!mounted) return;
    afterClose();
  }

  Future<void> _stopAndPipeline() async {
    _pipelineRunning = true;
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    _transcriptThrottleTimer?.cancel();
    _transcriptThrottleTimer = null;

    final session = ref.read(streamingVoiceSessionProvider);
    final orchestrator = ref.read(taskCreationOrchestratorProvider);

    widget.onClose();

    unawaited(
      orchestrator.enqueueVoicePipeline(
        session: session,
        onNeedDraftConfirm: widget.onNeedDraftConfirm,
      ),
    );
  }

  Future<void> _handleClose() async {
    if (_phase == _VoicePhase.recording) {
      await ref.read(streamingVoiceSessionProvider).cancel();
    } else if (!_pipelineRunning) {
      await ref.read(streamingVoiceSessionProvider).disposeSession();
    }
    await _animateClose(widget.onClose);
  }

  String _formatStartError(Object error) {
    if (error is StreamingVoiceException) return error.message;
    if (error is AsrSessionException) return error.message;
    if (error is VolcengineStreamingAsrException) return error.message;
    return '录音启动失败：$error';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _enterAnimation,
        builder: (context, child) {
          final t = _enterAnimation.value;
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.95 + t * 0.05,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _handleClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Color.lerp(
                Colors.transparent,
                AppTheme.sheetBarrierColor,
                _enterAnimation.value,
              ),
              alignment: Alignment.bottomCenter,
              child: GestureDetector(onTap: () {}, child: _buildSheet()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        border: Border(top: BorderSide(color: tokens.borderStrong, width: 1)),
        boxShadow: const [
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
                color: tokens.borderStrong,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[_buildErrorBar(), const SizedBox(height: 12)],
          _buildRecordMode(),
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
          const Icon(
            LucideIcons.circle_alert,
            size: 14,
            color: AppTheme.priorityP0,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.priorityP0,
                height: 1.4,
              ),
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
            color: tokens.bgSubtle,
            border: Border.all(color: tokens.borderStrong, width: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMicButton(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording ? '语音采音中 · 点击停止' : '点击麦克风开始采音',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '豆包 Seed ASR 2.0 · 流式识别',
                      style: AppTheme.mono(size: 10, color: tokens.fgSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _transcriptController,
          builder: (context, _) {
            if (!_isRecording && _transcriptController.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const SizedBox(height: 12), _buildTranscriptBox()],
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildTranscriptBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tokens.borderStrong, width: 0.8),
      ),
      child: TextField(
        controller: _transcriptController,
        readOnly: !_isRecording,
        maxLines: 3,
        minLines: 1,
        style: TextStyle(fontSize: 13, color: tokens.fgSecondary, height: 1.5),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: _isRecording ? '实时转写将显示在这里…' : null,
          hintStyle: TextStyle(color: tokens.fgSubtle, fontSize: 13),
        ),
      ),
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
                        border: Border.all(color: tokens.fg, width: 1),
                      ),
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            key: const ValueKey('voice-mic'),
            onTap: _toggleRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: recording ? tokens.fg : tokens.bgMuted,
                shape: BoxShape.circle,
                border: recording
                    ? null
                    : Border.all(color: tokens.borderStrong, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(
                recording ? LucideIcons.square : LucideIcons.mic,
                size: 18,
                color: recording ? tokens.bg : tokens.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _handleClose,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: tokens.bg,
          border: Border.all(color: tokens.borderStrong, width: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          '取消',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.fgMuted,
          ),
        ),
      ),
    );
  }
}
