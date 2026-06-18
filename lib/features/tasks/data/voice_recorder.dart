import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract class VoiceRecorder {
  Future<bool> hasPermission();

  Future<void> start();

  Future<String?> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class RecordVoiceRecorder implements VoiceRecorder {
  final AudioRecorder _recorder;
  String? _activePath;

  RecordVoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  @override
  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start() async {
    final directory = await getTemporaryDirectory();
    final path = p.join(
      directory.path,
      'tempo-voice-${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    _activePath = path;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
  }

  @override
  Future<String?> stop() async {
    final path = await _recorder.stop();
    _activePath = null;
    return path;
  }

  @override
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _activePath = null;
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }

  String? get activePath => _activePath;
}
