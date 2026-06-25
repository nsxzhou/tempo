import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/data/volcengine_streaming_asr.dart';

void main() {
  group('VolcengineStreamingAsrService', () {
    test('mock 模式 finish 返回固定转写', () async {
      final asr = VolcengineStreamingAsrService(
        sessionClient: _MockAsrSessionClient(),
      );

      await asr.start();
      final transcript = await asr.finish();

      expect(transcript, isNotEmpty);
      expect(transcript, contains('设计稿'));
    });
  });
}

class _MockAsrSessionClient implements AsrSessionClient {
  @override
  Future<AsrSessionConfig> fetchSession() async {
    return const AsrSessionConfig(
      authMode: 'relay',
      appKey: '',
      accessKey: '',
      resourceId: 'volc.seedasr.sauc.duration',
      wsEndpoint: 'wss://example.com/asr-relay',
      connectId: 'mock-connect-id',
      mock: true,
    );
  }
}
