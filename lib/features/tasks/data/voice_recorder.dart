import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

abstract class VoiceRecorder {
  Future<bool> hasPermission();

  /// 开始 PCM 16kHz mono 流式录音。
  Future<void> start();

  /// 录音中的 PCM 音频流（start 成功后非空）。
  Stream<Uint8List>? get audioStream;

  /// 停止录音并关闭音频流。
  Future<void> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class RecordVoiceRecorder implements VoiceRecorder {
  final AudioRecorder _recorder;
  StreamSubscription<Uint8List>? _streamSub;
  StreamController<Uint8List>? _audioController;

  RecordVoiceRecorder({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  @override
  Stream<Uint8List>? get audioStream => _audioController?.stream;

  @override
  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start() async {
    await _closeAudioStream();
    _audioController = StreamController<Uint8List>.broadcast();

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _streamSub = stream.listen(
      (chunk) {
        if (!(_audioController?.isClosed ?? true)) {
          _audioController!.add(chunk);
        }
      },
      onError: (Object error) {
        if (!(_audioController?.isClosed ?? true)) {
          _audioController!.addError(error);
        }
      },
    );
  }

  @override
  Future<void> stop() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _streamSub?.cancel();
    _streamSub = null;
    await _closeAudioStream();
  }

  @override
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _streamSub?.cancel();
    _streamSub = null;
    await _closeAudioStream();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    return _recorder.dispose();
  }

  Future<void> _closeAudioStream() async {
    await _audioController?.close();
    _audioController = null;
  }
}
