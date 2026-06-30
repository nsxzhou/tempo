// Volcengine 流式 ASR 客户端（WebSocket relay）

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';

import 'volcengine_asr_protocol.dart';

class AsrSessionConfig {
  final String authMode;
  final String resourceId;
  final String wsEndpoint;
  final String connectId;
  final bool mock;

  const AsrSessionConfig({
    this.authMode = 'relay',
    required this.resourceId,
    required this.wsEndpoint,
    required this.connectId,
    this.mock = false,
  });

  bool get usesRelay => authMode == 'relay';

  factory AsrSessionConfig.fromJson(Map<String, Object?> json) {
    return AsrSessionConfig(
      authMode: _readString(json['auth_mode']).isNotEmpty
          ? _readString(json['auth_mode'])
          : 'relay',
      resourceId: _readString(json['resource_id']),
      wsEndpoint: _readString(json['ws_endpoint']),
      connectId: _readString(json['connect_id']),
      mock: json['mock'] == true,
    );
  }
}

class AsrSessionException implements Exception {
  final String message;

  const AsrSessionException(this.message);

  @override
  String toString() => message;
}

class VolcengineStreamingAsrException implements Exception {
  final String message;

  const VolcengineStreamingAsrException(this.message);

  @override
  String toString() => message;
}

abstract class AsrSessionClient {
  Future<AsrSessionConfig> fetchSession();
}

class DioAsrSessionClient implements AsrSessionClient {
  final Dio _dio;
  final String _endpoint;
  final Map<String, String>? _headers;

  DioAsrSessionClient({
    required Dio dio,
    required String endpoint,
    Map<String, String>? headers,
  }) : _dio = dio,
       _endpoint = endpoint,
       _headers = headers;

  @override
  Future<AsrSessionConfig> fetchSession() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(headers: _headers),
      );
      final data = response.data;
      if (data == null) {
        throw const AsrSessionException('ASR 会话配置为空');
      }
      return AsrSessionConfig.fromJson(Map<String, Object?>.from(data));
    } on DioException catch (e) {
      final message = _readServerError(e.response?.data) ?? '无法获取 ASR 会话配置';
      throw AsrSessionException(message);
    }
  }
}

abstract class VolcengineStreamingAsr {
  Stream<String> get transcriptStream;

  String get currentTranscript;

  Future<void> start();

  void sendAudio(Uint8List chunk);

  Future<String> finish();

  Future<void> resetForNextUtterance();

  Future<void> cancel();
}

const Duration _asrFinishTimeout = Duration(seconds: 5);

class VolcengineStreamingAsrService implements VolcengineStreamingAsr {
  final AsrSessionClient _sessionClient;
  final Map<String, String>? _relayHeaders;

  IOWebSocketChannel? _channel;
  StreamSubscription<Object?>? _messageSub;
  final _transcriptController = StreamController<String>.broadcast();
  String _currentTranscript = '';
  bool _started = false;
  bool _receivedAnyPacket = false;
  Completer<void>? _finishCompleter;
  AsrSessionConfig? _session;
  int _seq = 1;
  String? _relayErrorMessage;

  VolcengineStreamingAsrService({
    required AsrSessionClient sessionClient,
    Map<String, String>? relayHeaders,
  }) : _sessionClient = sessionClient,
       _relayHeaders = relayHeaders;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  String get currentTranscript => _currentTranscript;

  @override
  Future<void> start() async {
    if (_started) return;

    _currentTranscript = '';
    _receivedAnyPacket = false;
    _finishCompleter = null;
    _seq = 1;
    _relayErrorMessage = null;

    _session = await _sessionClient.fetchSession();
    if (_session!.mock) {
      _started = true;
      return;
    }

    if (!_session!.usesRelay) {
      throw const VolcengineStreamingAsrException('ASR 会话必须使用 relay 模式');
    }

    final authHeaders = Map<String, String>.from(_relayHeaders ?? const {});
    final socket = await WebSocket.connect(
      _session!.wsEndpoint,
      headers: authHeaders.isEmpty ? null : authHeaders,
    );
    _channel = IOWebSocketChannel(socket);

    await _channel!.ready;
    _messageSub = _channel!.stream.listen(
      _handleMessage,
      onError: (Object error) {
        throw VolcengineStreamingAsrException('ASR 连接异常：$error');
      },
    );

    final configFrame = buildFullClientRequestFrame(
      buildDefaultAsrRequestPayload(),
      sequence: _seq,
    );
    _seq++;
    _channel!.sink.add(configFrame);

    _started = true;
  }

  @override
  void sendAudio(Uint8List chunk) {
    if (!_started) return;
    if (_session?.mock == true) return;
    if (chunk.isEmpty) return;
    _channel?.sink.add(
      buildAudioRequestFrame(chunk, sequence: _seq, isFinal: false),
    );
    _seq++;
  }

  @override
  Future<String> finish() async {
    if (!_started) return _currentTranscript;

    if (_session?.mock == true) {
      _currentTranscript = '明天下午三点提交设计稿，优先级高';
      _emitTranscript(_currentTranscript);
      await _cleanup();
      return _currentTranscript;
    }

    _finishCompleter = Completer<void>();
    _channel?.sink.add(
      buildAudioRequestFrame(Uint8List(0), sequence: 0, isFinal: true),
    );

    try {
      await _finishCompleter!.future.timeout(_asrFinishTimeout);
    } on TimeoutException {
      // Fall through to reset and validate transcript below.
    }

    final transcript = _currentTranscript;
    if (transcript.trim().isEmpty) {
      await _cleanup();
      if (_relayErrorMessage != null) {
        throw VolcengineStreamingAsrException(_relayErrorMessage!);
      }
      if (!_receivedAnyPacket) {
        throw const VolcengineStreamingAsrException('ASR 未返回识别结果，请检查网络后重试。');
      }
      throw const VolcengineStreamingAsrException('语音识别结果为空，请重试。');
    }

    await _softReset();
    return transcript;
  }

  String _formatRelayUpstreamError(String message) {
    if (message.contains('403')) {
      return 'ASR 上游鉴权失败（403），请确认已开通「大模型流式语音识别 2.0」'
          '且 VOLCENGINE_ASR_API_KEY 对应资源 volc.seedasr.sauc.duration';
    }
    return 'ASR 中继异常：$message';
  }

  @override
  Future<void> resetForNextUtterance() async {
    if (!_started) return;
    await _softReset();
  }

  @override
  Future<void> cancel() async {
    await _cleanup();
  }

  void _handleMessage(Object? message) {
    if (message is! List<int>) {
      if (message is String) {
        try {
          final decoded = jsonDecode(message);
          if (decoded is Map && decoded['__relay'] is Map) {
            final relay = Map<String, Object?>.from(decoded['__relay'] as Map);
            final phase = relay['phase'];
            final relayMessage = relay['message'];
            if (phase == 'upstream_error' &&
                relayMessage is String &&
                relayMessage.isNotEmpty) {
              _relayErrorMessage = _formatRelayUpstreamError(relayMessage);
            }
          }
        } catch (_) {
          // ignore non-json text frames
        }
      }
      return;
    }
    final bytes = Uint8List.fromList(message);
    final packet = parseServerPacket(bytes);
    switch (packet) {
      case VolcengineAsrResponse(:final data, :final isFinal):
        _receivedAnyPacket = true;
        final transcript = extractTranscriptFromPayload(data);
        if (transcript != null && transcript.isNotEmpty) {
          _currentTranscript = transcript;
          _emitTranscript(transcript);
        }
        if (isFinal || _currentTranscript.trim().isNotEmpty) {
          _completeFinishWait();
        }
      case VolcengineAsrError(:final code, :final message):
        _receivedAnyPacket = true;
        throw VolcengineStreamingAsrException('ASR 错误($code)：$message');
      case VolcengineAsrUnknown():
        break;
    }
  }

  void _completeFinishWait() {
    final completer = _finishCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  void _emitTranscript(String text) {
    if (!_transcriptController.isClosed) {
      _transcriptController.add(text);
    }
  }

  Future<void> _softReset() async {
    _currentTranscript = '';
    _receivedAnyPacket = false;
    _finishCompleter = null;
    _relayErrorMessage = null;
    _seq = 1;

    if (_session?.mock == true) {
      return;
    }

    if (_channel == null) {
      _started = false;
      return;
    }

    final configFrame = buildFullClientRequestFrame(
      buildDefaultAsrRequestPayload(),
      sequence: _seq,
    );
    _seq++;
    _channel!.sink.add(configFrame);
    _started = true;
  }

  Future<void> _cleanup() async {
    _started = false;
    _completeFinishWait();
    _finishCompleter = null;
    await _messageSub?.cancel();
    _messageSub = null;
    await _channel?.sink.close();
    _channel = null;
    _session = null;
  }
}

String _readString(Object? value) {
  return value is String ? value : '';
}

String? _readServerError(Object? data) {
  if (data is Map) {
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
  }
  return null;
}
