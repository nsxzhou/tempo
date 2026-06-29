// VoiceCaptureOverlay — 微信式语音浮岛
// 长按 FAB 录音 → 实时字幕 → 松手 processing → 完成关闭

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../data/streaming_voice_session.dart';
import '../../data/task_creation_orchestrator.dart';
import '../../data/volcengine_streaming_asr.dart';

enum VoiceCapturePhase { recording, processing }

class VoiceCaptureOverlay extends StatefulWidget {
  final VoiceCapturePhase phase;
  final bool slideCancelActive;
  final VoicePipelinePhase? pipelinePhase;
  final String transcript;
  final String? error;

  const VoiceCaptureOverlay({
    super.key,
    required this.phase,
    required this.slideCancelActive,
    required this.pipelinePhase,
    required this.transcript,
    required this.error,
  });

  @override
  State<VoiceCaptureOverlay> createState() => _VoiceCaptureOverlayState();
}

class _VoiceCaptureOverlayState extends State<VoiceCaptureOverlay>
    with SingleTickerProviderStateMixin {
  TempoTokens get tokens => context.tokens;

  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (widget.error != null) return widget.error!;
    if (widget.phase == VoiceCapturePhase.recording) {
      return widget.slideCancelActive ? '松开取消' : '松手结束，上滑取消';
    }
    return switch (widget.pipelinePhase) {
      VoicePipelinePhase.parsing => '解析中…',
      VoicePipelinePhase.transcribing || null => '识别中…',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cancelTone = widget.slideCancelActive;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: AppTheme.sheetBarrierColor.withValues(alpha: 0.72),
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 140 + MediaQuery.paddingOf(context).bottom),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: cancelTone ? AppTheme.priorityP0Border : tokens.borderStrong,
                width: cancelTone ? 1.2 : 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _statusLabel,
                  style: AppTheme.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: cancelTone ? AppTheme.priorityP0 : tokens.fgMuted,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                _buildWaveBars(cancelTone),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  child: Text(
                    widget.transcript.isEmpty
                        ? (widget.phase == VoiceCapturePhase.recording
                              ? '正在聆听…'
                              : '…')
                        : widget.transcript,
                    key: ValueKey(widget.transcript),
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: tokens.fg,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.phase == VoiceCapturePhase.processing) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.fgMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBars(bool cancelTone) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final phase = _waveController.value + index * 0.15;
            final height = 8 + math.sin(phase * math.pi * 2) * 6 + index * 1.5;
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: cancelTone ? AppTheme.priorityP0 : tokens.fg,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            );
          }),
        );
      },
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
