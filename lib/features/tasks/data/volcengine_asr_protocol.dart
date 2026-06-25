// Volcengine ASR v3 WebSocket 二进制协议编解码

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const int _protocolVersion = 0x01;
const int _headerSizeUnits = 0x01;

const int messageTypeFullClientRequest = 0x01;
const int messageTypeAudioOnlyRequest = 0x02;
const int messageTypeFullServerResponse = 0x09;
const int messageTypeError = 0x0f;

const int serializationJson = 0x01;
const int serializationNone = 0x00;

const int compressionGzip = 0x01;
const int compressionNone = 0x00;

const int messageTypeSpecificFlagsPosSequence = 0x01;
const int messageTypeSpecificFlagsLastAudio = 0x02;

Uint8List buildHeader({
  required int messageType,
  required int messageTypeFlags,
  required int serialization,
  required int compression,
}) {
  return Uint8List.fromList([
    (_protocolVersion << 4) | _headerSizeUnits,
    (messageType << 4) | messageTypeFlags,
    (serialization << 4) | compression,
    0x00,
  ]);
}

Uint8List buildFullClientRequestFrame(
  Map<String, Object?> payload, {
  required int sequence,
}) {
  final payloadRaw = utf8.encode(jsonEncode(payload));
  final payloadCompressed = Uint8List.fromList(gzip.encode(payloadRaw));
  final header = buildHeader(
    messageType: messageTypeFullClientRequest,
    messageTypeFlags: messageTypeSpecificFlagsPosSequence,
    serialization: serializationJson,
    compression: compressionGzip,
  );
  return Uint8List.fromList([
    ...header,
    ..._int32Be(sequence),
    ..._uint32Be(payloadCompressed.length),
    ...payloadCompressed,
  ]);
}

Uint8List buildAudioRequestFrame(
  Uint8List audio, {
  required int sequence,
  required bool isFinal,
}) {
  final payloadCompressed = Uint8List.fromList(gzip.encode(audio));
  final header = buildHeader(
    messageType: messageTypeAudioOnlyRequest,
    messageTypeFlags: isFinal
        ? messageTypeSpecificFlagsLastAudio
        : messageTypeSpecificFlagsPosSequence,
    serialization: serializationNone,
    compression: compressionGzip,
  );
  final frame = <int>[...header];
  if (!isFinal) {
    frame.addAll(_int32Be(sequence));
  }
  frame.addAll(_uint32Be(payloadCompressed.length));
  frame.addAll(payloadCompressed);
  return Uint8List.fromList(frame);
}

List<int> _uint32Be(int value) {
  return [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];
}

List<int> _int32Be(int value) {
  final bytes = ByteData(4)..setInt32(0, value, Endian.big);
  return bytes.buffer.asUint8List();
}

sealed class VolcengineAsrPacket {}

class VolcengineAsrResponse extends VolcengineAsrPacket {
  final Map<String, Object?> data;
  final bool isFinal;

  VolcengineAsrResponse({required this.data, required this.isFinal});
}

class VolcengineAsrError extends VolcengineAsrPacket {
  final int code;
  final String message;

  VolcengineAsrError({required this.code, required this.message});
}

class VolcengineAsrUnknown extends VolcengineAsrPacket {}

VolcengineAsrPacket parseServerPacket(Uint8List data) {
  if (data.length < 4) return VolcengineAsrUnknown();

  final headerSizeUnits = data[0] & 0x0f;
  final headerSize = headerSizeUnits * 4;
  final messageType = (data[1] >> 4) & 0x0f;
  final messageTypeFlags = data[1] & 0x0f;
  final serialization = (data[2] >> 4) & 0x0f;
  final compression = data[2] & 0x0f;
  var offset = headerSize;

  if ((messageTypeFlags & messageTypeSpecificFlagsPosSequence) != 0) {
    if (data.length < offset + 4) return VolcengineAsrUnknown();
    offset += 4;
  }
  if ((messageTypeFlags & 0x04) != 0) {
    if (data.length < offset + 4) return VolcengineAsrUnknown();
    offset += 4;
  }

  if (messageType == messageTypeFullServerResponse) {
    if (data.length < offset + 4) return VolcengineAsrUnknown();

    final payloadSize = _readUint32Be(data, offset);
    offset += 4;
    final payloadEnd = offset + payloadSize;
    if (payloadEnd > data.length) return VolcengineAsrUnknown();

    var payload = data.sublist(offset, payloadEnd);
    if (compression == compressionGzip && payload.isNotEmpty) {
      payload = Uint8List.fromList(gzip.decode(payload));
    }

    Object? decoded = utf8.decode(payload);
    if (serialization == serializationJson && payload.isNotEmpty) {
      decoded = jsonDecode(decoded as String);
    }

    return VolcengineAsrResponse(
      data: decoded is Map
          ? Map<String, Object?>.from(decoded)
          : <String, Object?>{},
      isFinal:
          messageTypeFlags & messageTypeSpecificFlagsLastAudio != 0 ||
          messageTypeFlags == 0x03,
    );
  }

  if (messageType == messageTypeError) {
    if (data.length < offset + 4) {
      return VolcengineAsrError(code: 0, message: 'Unknown ASR server error');
    }
    final code = _readUint32Be(data, offset);
    offset += 4;
    if (data.length < offset + 4) {
      return VolcengineAsrError(
        code: code,
        message: 'Unknown ASR server error',
      );
    }
    final size = _readUint32Be(data, offset);
    offset += 4;
    final messageEnd = offset + size;
    if (messageEnd > data.length) {
      return VolcengineAsrError(
        code: code,
        message: 'Unknown ASR server error',
      );
    }
    final message = utf8.decode(data.sublist(offset, messageEnd));
    return VolcengineAsrError(code: code, message: message);
  }

  return VolcengineAsrUnknown();
}

int _readUint32Be(Uint8List data, int offset) {
  return (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];
}

String? extractTranscriptFromPayload(Map<String, Object?> payload) {
  final result = payload['result'];
  if (result is Map) {
    final text = result['text'];
    if (text is String && text.trim().isNotEmpty) {
      return text.trim();
    }

    final utterances = result['utterances'];
    if (utterances is List) {
      final parts = <String>[];
      for (final item in utterances) {
        if (item is Map) {
          final utteranceText = item['text'];
          if (utteranceText is String && utteranceText.trim().isNotEmpty) {
            parts.add(utteranceText.trim());
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('');
    }
  }
  if (result is List) {
    final parts = <String>[];
    for (final item in result) {
      if (item is Map) {
        final text = item['text'];
        if (text is String && text.trim().isNotEmpty) {
          parts.add(text.trim());
        }
      }
    }
    if (parts.isNotEmpty) return parts.join('');
  }
  return null;
}

Map<String, Object?> buildDefaultAsrRequestPayload() {
  return {
    'user': {'uid': 'tempo-voice'},
    'audio': {
      'format': 'pcm',
      'codec': 'raw',
      'rate': 16000,
      'bits': 16,
      'channel': 1,
    },
    'request': {
      'model_name': 'bigmodel',
      'enable_itn': true,
      'enable_punc': true,
      'result_type': 'single',
      'end_window_size': 800,
    },
  };
}
