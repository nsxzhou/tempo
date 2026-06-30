import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../data/task_creation_orchestrator.dart';
import 'widgets/quick_create_sheet.dart';
import 'widgets/voice_overlay.dart';

enum VoiceCaptureState { inactive, armed, recording, processing }

mixin TasksPageVoiceMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  VoiceCaptureState voiceCapture = VoiceCaptureState.inactive;
  String voiceTranscript = '';
  String? voiceError;
  VoicePipelinePhase? pipelinePhase;
  StreamSubscription<String>? transcriptSub;

  void armVoiceCapture() {
    ref.read(shellTabBarVisibleProvider.notifier).state = false;
    setState(() {
      voiceCapture = VoiceCaptureState.armed;
      voiceTranscript = '';
      voiceError = null;
      pipelinePhase = null;
    });
  }

  void onVoiceOverlayPrimaryTap() {
    switch (voiceCapture) {
      case VoiceCaptureState.armed:
        unawaited(startVoiceRecording());
      case VoiceCaptureState.recording:
        endVoiceCapture();
      case VoiceCaptureState.inactive:
      case VoiceCaptureState.processing:
        break;
    }
  }

  void cancelVoiceCapture() {
    if (voiceCapture == VoiceCaptureState.processing) return;
    unawaited(ref.read(streamingVoiceSessionProvider).cancel());
    closeVoiceCapture();
  }

  Future<void> startVoiceRecording() async {
    final session = ref.read(streamingVoiceSessionProvider);
    try {
      if (!session.isPrepared) {
        await session.prepare();
      }
      if (!mounted || voiceCapture != VoiceCaptureState.armed) return;
      setState(() => voiceCapture = VoiceCaptureState.recording);
      await session.startRecording();
      if (!mounted || voiceCapture != VoiceCaptureState.recording) return;

      transcriptSub?.cancel();
      transcriptSub = session.transcriptStream.listen((text) {
        if (!mounted) return;
        setState(() => voiceTranscript = text);
        ref.read(textParseServiceProvider).parseTextDebounced(text);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        voiceError = formatVoiceStartError(e);
        voiceCapture = VoiceCaptureState.inactive;
      });
      ref.read(shellTabBarVisibleProvider.notifier).state = true;
    }
  }

  void endVoiceCapture() {
    if (voiceCapture != VoiceCaptureState.recording) return;

    transcriptSub?.cancel();
    transcriptSub = null;

    setState(() {
      voiceCapture = VoiceCaptureState.processing;
      pipelinePhase = VoicePipelinePhase.transcribing;
    });

    unawaited(runVoicePipeline());
  }

  Future<void> runVoicePipeline() async {
    final session = ref.read(streamingVoiceSessionProvider);
    final orchestrator = ref.read(taskCreationOrchestratorProvider);

    await orchestrator.enqueueVoicePipeline(
      session: session,
      partialTranscript: voiceTranscript,
      onNeedDraftConfirm: (draft) {
        if (!mounted) return;
        unawaited(QuickCreateSheet.showPrefill(context, draft: draft));
      },
      onPhaseChanged: (phase) {
        if (!mounted) return;
        setState(() => pipelinePhase = phase);
      },
      onComplete: closeVoiceCapture,
    );
  }

  void closeVoiceCapture() {
    if (!mounted) return;
    setState(() {
      voiceCapture = VoiceCaptureState.inactive;
      voiceTranscript = '';
      voiceError = null;
      pipelinePhase = null;
    });
    ref.read(shellTabBarVisibleProvider.notifier).state = true;
    unawaited(ref.read(streamingVoiceSessionProvider).disposeSession());
  }

  void disposeVoiceMixin() {
    transcriptSub?.cancel();
  }

  VoiceCaptureOverlay? buildVoiceOverlay() {
    if (voiceCapture == VoiceCaptureState.inactive) return null;
    return VoiceCaptureOverlay(
      phase: switch (voiceCapture) {
        VoiceCaptureState.armed => VoiceCapturePhase.armed,
        VoiceCaptureState.recording => VoiceCapturePhase.recording,
        VoiceCaptureState.processing ||
        VoiceCaptureState.inactive =>
          VoiceCapturePhase.processing,
      },
      pipelinePhase: pipelinePhase,
      transcript: voiceTranscript,
      error: voiceError,
      onPrimaryTap: onVoiceOverlayPrimaryTap,
      onCancel: cancelVoiceCapture,
    );
  }
}
