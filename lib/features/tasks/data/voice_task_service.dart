import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'voice_task_parse_result.dart';

abstract class VoiceTaskService {
  Future<VoiceTaskParseResult> parseAudioFile(String path);

  Future<VoiceTaskParseResult> parseAudioBytes(
    Uint8List bytes, {
    String filename = 'voice-task.m4a',
  });
}

class DioVoiceTaskService implements VoiceTaskService {
  final Dio _dio;
  final String endpoint;

  DioVoiceTaskService({required Dio dio, required this.endpoint}) : _dio = dio;

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
    // Edge Function 内部执行 Storage 上传 → ASR 提交+轮询 → LLM 解析,
    // 整体耗时可达 30-40 秒,需要覆盖默认的 receiveTimeout。
    final response = await _dio.post<Object?>(
      endpoint,
      data: formData,
      options: Options(
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    return _parseResponse(response.data);
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
