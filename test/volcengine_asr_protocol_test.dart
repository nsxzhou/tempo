import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/data/volcengine_asr_protocol.dart';

void main() {
  group('volcengine_asr_protocol', () {
    test('buildFullClientRequestFrame 生成合法帧头', () {
      final frame = buildFullClientRequestFrame(
        buildDefaultAsrRequestPayload(),
        sequence: 1,
      );
      expect(frame.length, greaterThan(12));
      expect(frame[0], 0x11);
      expect((frame[1] >> 4) & 0x0f, messageTypeFullClientRequest);
      expect(frame[1] & 0x0f, messageTypeSpecificFlagsPosSequence);
    });

    test('extractTranscriptFromPayload 读取 result.text', () {
      final text = extractTranscriptFromPayload({
        'result': {'text': '明天下午三点开会'},
      });
      expect(text, '明天下午三点开会');
    });

    test('extractTranscriptFromPayload 降级读取 result.utterances', () {
      final text = extractTranscriptFromPayload({
        'result': {
          'utterances': [
            {'text': '星期四'},
            {'text': '去吃 KFC。'},
          ],
        },
      });
      expect(text, '星期四去吃 KFC。');
    });

    test('parseServerPacket 解析 gzip JSON 响应', () {
      final payload = jsonEncode({
        'result': {'text': '提交设计稿'},
      });
      final compressed = Uint8List.fromList(gzip.encode(utf8.encode(payload)));

      final header = buildHeader(
        messageType: messageTypeFullServerResponse,
        messageTypeFlags: messageTypeSpecificFlagsPosSequence,
        serialization: serializationJson,
        compression: compressionGzip,
      );
      final packetBytes = Uint8List.fromList([
        ...header,
        0, 0, 0, 0, // sequence placeholder
        ..._uint32Be(compressed.length),
        ...compressed,
      ]);
      // Fix sequence bytes at offset 4-7 (already 0)

      final parsed = parseServerPacket(packetBytes);
      expect(parsed, isA<VolcengineAsrResponse>());
      final response = parsed as VolcengineAsrResponse;
      expect(
        extractTranscriptFromPayload(response.data),
        '提交设计稿',
      );
    });
  });
}

List<int> _uint32Be(int value) {
  return [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];
}
