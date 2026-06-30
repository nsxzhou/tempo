// VoiceCaptureOverlay — 贴底全宽语音 Bottom Sheet
// armed → 轻触开始 → recording → 再次轻触结束 → processing

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
    with TickerProviderStateMixin {
  static const double _swipeCancelThreshold = 60;
  static const double _micSize = 72;

  TempoTokens get tokens => context.tokens;

  late final AnimationController _breathController;
  late final AnimationController _entryController;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _barrierOpacity;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: AppTheme.durationMedium,
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: AppTheme.curveOrganic,
          ),
        );
    _barrierOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.85, curve: Curves.easeOut),
    );
    _entryController.forward();
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
    _entryController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (widget.error != null) return widget.error!;
    return switch (widget.phase) {
      VoiceCapturePhase.armed => '轻触开始录音',
      VoiceCapturePhase.recording => '再次轻触结束',
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final dragCancelActive = _dragOffset > _swipeCancelThreshold;
    final borderColor = dragCancelActive
        ? AppTheme.priorityP0Border
        : tokens.borderStrong;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _barrierOpacity,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: widget.onCancel,
                  child: _GradientBarrier(opacity: _barrierOpacity.value),
                ),
                child!,
              ],
            );
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _entrySlide,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (widget.phase == VoiceCapturePhase.processing) return;
                  setState(() {
                    _dragOffset = (_dragOffset + details.delta.dy).clamp(
                      0,
                      160,
                    );
                  });
                  if (_dragOffset > _swipeCancelThreshold) {
                    widget.onCancel();
                    setState(() => _dragOffset = 0);
                  }
                },
                onVerticalDragEnd: (_) => setState(() => _dragOffset = 0),
                child: Transform.translate(
                  offset: Offset(0, _dragOffset * 0.45),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tokens.bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                      border: Border(
                        top: BorderSide(color: borderColor, width: 0.8),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 30,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 16),
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
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 72),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 120),
                              child: Text(
                                _transcriptText,
                                key: ValueKey(_transcriptText),
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.fg,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(child: _buildMicButton()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final enabled = widget.phase != VoiceCapturePhase.processing;

    return GestureDetector(
      key: const Key('voice_mic_button'),
      onTap: enabled ? widget.onPrimaryTap : null,
      child: _buildMicButtonVisual(),
    );
  }

  Widget _buildMicButtonVisual() {
    if (widget.phase == VoiceCapturePhase.recording) {
      return AnimatedBuilder(
        animation: _breathController,
        builder: (context, child) {
          final t = _breathController.value;
          final ringScale = 1 + t * 0.22;
          final ringOpacity = 0.14 + t * 0.38;
          return SizedBox(
            width: _micSize,
            height: _micSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: ringOpacity,
                  child: Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: _micSize + 12,
                      height: _micSize + 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.fg, width: 1.5),
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: _micCore(showBreathDot: true),
      );
    }

    if (widget.phase == VoiceCapturePhase.processing) {
      return SizedBox(
        width: _micSize,
        height: _micSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _micCore(muted: true),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.fgMuted,
              ),
            ),
          ],
        ),
      );
    }

    return _micCore();
  }

  Widget _micCore({bool muted = false, bool showBreathDot = false}) {
    return Container(
      width: _micSize,
      height: _micSize,
      decoration: BoxDecoration(
        color: muted ? tokens.bgMuted : tokens.fg,
        shape: BoxShape.circle,
        border: Border.all(
          color: muted ? tokens.borderStrong : tokens.fg,
          width: 0.8,
        ),
        boxShadow: showBreathDot ? AppTheme.shadowSelectedDot : null,
      ),
      alignment: Alignment.center,
      child: showBreathDot
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: tokens.bg,
                shape: BoxShape.circle,
              ),
            )
          : Icon(
              LucideIcons.mic,
              size: 28,
              color: muted ? tokens.fgMuted : tokens.bg,
            ),
    );
  }
}

/// 渐变暗角遮罩：顶部浅、底部深，居中径向强化焦点。
class _GradientBarrier extends StatelessWidget {
  const _GradientBarrier({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  AppTheme.sheetBarrierColor.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.5, 1.0),
                radius: 0.55,
                colors: [
                  AppTheme.sheetBarrierColor.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
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
