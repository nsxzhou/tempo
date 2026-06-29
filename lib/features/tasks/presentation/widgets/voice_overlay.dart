// VoiceCaptureOverlay — 极简语音浮岛
// armed → 点击开始 → recording → 点击结束 → processing

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../data/streaming_voice_session.dart';
import '../../data/task_creation_orchestrator.dart';
import '../../data/volcengine_streaming_asr.dart';

enum VoiceCapturePhase { armed, recording, processing }

class VoiceCaptureOverlay extends StatefulWidget {
  final VoiceCapturePhase phase;
  final VoicePipelinePhase? pipelinePhase;
  final String transcript;
  final String? error;
  final VoidCallback onPrimaryTap;
  final VoidCallback onCancel;

  const VoiceCaptureOverlay({
    super.key,
    required this.phase,
    required this.pipelinePhase,
    required this.transcript,
    required this.error,
    required this.onPrimaryTap,
    required this.onCancel,
  });

  @override
  State<VoiceCaptureOverlay> createState() => _VoiceCaptureOverlayState();
}

class _VoiceCaptureOverlayState extends State<VoiceCaptureOverlay>
    with SingleTickerProviderStateMixin {
  static const double _swipeCancelThreshold = 60;

  TempoTokens get tokens => context.tokens;

  late final AnimationController _breathController;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncBreathAnimation();
  }

  @override
  void didUpdateWidget(covariant VoiceCaptureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) {
      _syncBreathAnimation();
    }
  }

  void _syncBreathAnimation() {
    if (widget.phase == VoiceCapturePhase.recording) {
      if (!_breathController.isAnimating) {
        _breathController.repeat(reverse: true);
      }
    } else {
      _breathController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (widget.error != null) return widget.error!;
    return switch (widget.phase) {
      VoiceCapturePhase.armed => '点击开始录音',
      VoiceCapturePhase.recording => '再次点击结束',
      VoiceCapturePhase.processing => switch (widget.pipelinePhase) {
        VoicePipelinePhase.parsing => '解析中…',
        VoicePipelinePhase.transcribing || null => '识别中…',
      },
    };
  }

  String get _transcriptText {
    if (widget.transcript.isNotEmpty) return widget.transcript;
    return switch (widget.phase) {
      VoiceCapturePhase.armed => '准备好后轻触开始',
      VoiceCapturePhase.recording => '正在聆听…',
      VoiceCapturePhase.processing => '…',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dragCancelActive = _dragOffset > _swipeCancelThreshold;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: AppTheme.sheetBarrierColor.withValues(alpha: 0.72),
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            120 + MediaQuery.paddingOf(context).bottom,
          ),
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (widget.phase == VoiceCapturePhase.processing) return;
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 120);
              });
              if (_dragOffset > _swipeCancelThreshold) {
                widget.onCancel();
                setState(() => _dragOffset = 0);
              }
            },
            onVerticalDragEnd: (_) => setState(() => _dragOffset = 0),
            child: Transform.translate(
              offset: Offset(0, _dragOffset * 0.35),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: tokens.bg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: dragCancelActive
                        ? AppTheme.priorityP0Border
                        : tokens.borderStrong,
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _statusLabel,
                            style: AppTheme.mono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: tokens.fgMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (widget.phase != VoiceCapturePhase.processing)
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Text(
                              '取消',
                              style: tokens.mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: tokens.fgMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: widget.phase == VoiceCapturePhase.processing
                          ? null
                          : widget.onPrimaryTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          _buildIndicator(),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                            child: Text(
                              _transcriptText,
                              key: ValueKey(_transcriptText),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: tokens.fg,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    if (widget.phase == VoiceCapturePhase.recording) {
      return AnimatedBuilder(
        animation: _breathController,
        builder: (context, _) {
          final t = _breathController.value;
          final scale = 0.85 + t * 0.15;
          final opacity = 0.5 + t * 0.5;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tokens.fg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }

    return Icon(
      LucideIcons.mic,
      size: 18,
      color: widget.phase == VoiceCapturePhase.processing
          ? tokens.fgMuted
          : tokens.fg,
    );
  }
}

/// 格式化录音启动错误。
String formatVoiceStartError(Object error) {
  if (error is StreamingVoiceException) return error.message;
  if (error is AsrSessionException) return error.message;
  if (error is VolcengineStreamingAsrException) return error.message;
  return '录音启动失败：$error';
}
