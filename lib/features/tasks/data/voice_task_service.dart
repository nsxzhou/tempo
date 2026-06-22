import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'voice_task_parse_result.dart';

/// 语音解析失败时抛出的用户可读异常。
class VoiceTaskException implements Exception {
  final String message;
  final int? statusCode;

  const VoiceTaskException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

abstract class VoiceTaskService {
  /// Legacy：multipart 音频上传路径（流式 ASR 不可用时的降级）。
  Future<VoiceTaskParseResult> parseAudioFile(String path);

  Future<VoiceTaskParseResult> parseAudioBytes(
    Uint8List bytes, {
    String filename = 'voice-task.m4a',
  });
}

class DioVoiceTaskService implements VoiceTaskService {
  final Dio _dio;
  final String endpoint;
  final Map<String, String>? headers;

  DioVoiceTaskService({
    required Dio dio,
    required this.endpoint,
    this.headers,
  }) : _dio = dio;

  @override
  Future<VoiceTaskParseResult> parseAudioFile(String path) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(path, filename: p.basename(path)),
    });
    return _postFormData(formData);
  }

  @override
  Future<VoiceTaskParseResult> parseAudioBytes(
    Uint8List bytes, {
    String filename = 'voice-task.m4a',
  }) async {
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _postFormData(formData);
  }

  Future<VoiceTaskParseResult> _postFormData(FormData formData) async {
    try {
      // Edge Function 内部执行 Storage 上传 → ASR 提交+轮询 → LLM 解析,
      // 整体耗时可达 30-40 秒,需要覆盖默认的 receiveTimeout。
      final response = await _dio.post<Object?>(
        endpoint,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 20),
          headers: headers,
        ),
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw VoiceTaskException('语音解析结果格式错误：${e.message}');
    }
  }

  VoiceTaskException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) {
      return const VoiceTaskException(
        '语音解析服务未就绪，请确认 parse-task 已部署。',
        statusCode: 404,
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return VoiceTaskException(
        '语音解析鉴权失败（$statusCode）。',
        statusCode: statusCode,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      final serverMessage = _readServerError(e.response?.data);
      if (serverMessage != null) {
        return VoiceTaskException(serverMessage, statusCode: statusCode);
      }
      return VoiceTaskException(
        '语音解析服务暂时不可用（$statusCode）。',
        statusCode: statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const VoiceTaskException('语音解析请求超时，请稍后重试。');
      case DioExceptionType.connectionError:
        return const VoiceTaskException('无法连接语音解析服务，请检查网络。');
      default:
        break;
    }

    final serverMessage = _readServerError(e.response?.data);
    if (serverMessage != null) {
      return VoiceTaskException(serverMessage, statusCode: statusCode);
    }

    return VoiceTaskException(
      '语音解析失败${statusCode != null ? '（$statusCode）' : ''}。',
      statusCode: statusCode,
    );
  }

  String? _readServerError(Object? data) {
    if (data is Map) {
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  VoiceTaskParseResult _parseResponse(Object? data) {
    final payload = switch (data) {
      Map<String, Object?> map => map,
      Map map => Map<String, Object?>.from(map),
      String text => Map<String, Object?>.from(jsonDecode(text) as Map),
      _ => throw const FormatException('Invalid voice-task response payload'),
    };

    return VoiceTaskParseResult.fromJson(payload);
  }
}
