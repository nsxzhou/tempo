// 流式语音会话：PCM 录音 + Volcengine 流式 ASR

import 'dart:async';
import 'dart:typed_data';

import 'volcengine_streaming_asr.dart';
import 'voice_recorder.dart';

class StreamingVoiceException implements Exception {
  final String message;

  const StreamingVoiceException(this.message);

  @override
  String toString() => message;
}

abstract class StreamingVoiceSession {
  Stream<String> get transcriptStream;

  String get currentTranscript;

  bool get isRecording;

  bool get isPrepared;

  /// 预热 ASR（打开语音层时调用）。
  Future<void> prepare();

  /// 预检麦克风权限（Tasks 页进入时调用）。
  Future<bool> ensureMicPermission();

  /// 开始录音（点麦克风；乐观 UI 后调用）。
  Future<void> startRecording();

  /// 释放预热连接（未录音时关闭 overlay）。
  Future<void> disposeSession();

  /// 兼容旧路径：prepare + startRecording。
  Future<void> start();

  Future<String> stopAndGetTranscript();

  Future<void> cancel();
}

class LiveStreamingVoiceSession implements StreamingVoiceSession {
  final VoiceRecorder _recorder;
  final VolcengineStreamingAsr _asr;

  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<String>? _asrSub;
  String _currentTranscript = '';
  bool _asrPrepared = false;
  bool _recording = false;
  Future<void>? _prepareFuture;
  final List<Uint8List> _audioBuffer = [];

  LiveStreamingVoiceSession({
    required VoiceRecorder recorder,
    required VolcengineStreamingAsr asr,
  }) : _recorder = recorder,
       _asr = asr;

  @override
  Stream<String> get transcriptStream => _asr.transcriptStream;

  @override
  String get currentTranscript => _currentTranscript;

  @override
  bool get isRecording => _recording;

  @override
  bool get isPrepared => _asrPrepared;

  @override
  Future<bool> ensureMicPermission() => _recorder.hasPermission();

  @override
  Future<void> prepare() {
    if (_asrPrepared) return Future.value();
    _prepareFuture ??= _doPrepare();
    return _prepareFuture!;
  }

  Future<void> _doPrepare() async {
    try {
      await _asr.start();
      _asrPrepared = true;
    } catch (e) {
      _prepareFuture = null;
      rethrow;
    }
  }

  @override
  Future<void> startRecording() async {
    if (_recording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const StreamingVoiceException('需要麦克风权限才能语音创建任务。');
    }

    _currentTranscript = '';
    _audioBuffer.clear();

    await _recorder.start();
    final audioStream = _recorder.audioStream;
    if (audioStream == null) {
      throw const StreamingVoiceException('录音流未就绪，请重试。');
    }

    _asrSub?.cancel();
    _asrSub = _asr.transcriptStream.listen((text) {
      _currentTranscript = text;
    });

    _audioSub?.cancel();
    _audioSub = audioStream.listen(_onAudioChunk);

    _recording = true;

    if (!_asrPrepared) {
      await prepare();
      _flushAudioBuffer();
    }
  }

  void _onAudioChunk(Uint8List chunk) {
    if (_asrPrepared) {
      _asr.sendAudio(chunk);
    } else {
      _audioBuffer.add(chunk);
    }
  }

  void _flushAudioBuffer() {
    for (final chunk in _audioBuffer) {
      _asr.sendAudio(chunk);
    }
    _audioBuffer.clear();
  }

  @override
  Future<void> start() async {
    await prepare();
    await startRecording();
  }

  @override
  Future<String> stopAndGetTranscript() async {
    if (!_recording) {
      return _currentTranscript;
    }
    _recording = false;

    await _recorder.stop();
    await _audioSub?.cancel();
    _audioSub = null;

    final transcript = await _asr.finish();
    _currentTranscript = transcript;

    await _asrSub?.cancel();
    _asrSub = null;
    _audioBuffer.clear();
    _asrPrepared = false;
    _prepareFuture = null;

    return transcript;
  }

  @override
  Future<void> disposeSession() async {
    if (_recording) return;
    await cancel();
  }

  @override
  Future<void> cancel() async {
    _recording = false;
    await _audioSub?.cancel();
    await _asrSub?.cancel();
    _audioSub = null;
    _asrSub = null;
    _audioBuffer.clear();
    await _recorder.cancel();
    await _asr.cancel();
    _currentTranscript = '';
    _asrPrepared = false;
    _prepareFuture = null;
  }
}
