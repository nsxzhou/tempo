// ============================================================
// TextParseService — 文本 LLM 解析服务
// 调用 parse-task Edge Function JSON 路径，支持防抖预解析与缓存
// ============================================================

import 'dart:async';

import 'package:dio/dio.dart';

import 'voice_task_parse_result.dart';

/// 文本 LLM 解析服务。
///
/// 调用 parse-task Edge Function 的 JSON 文本路径，
/// 将自然语言文本解析为结构化任务字段（标题/日期/优先级/tag）。
class TextParseService {
  static const Duration debounceDuration = Duration(milliseconds: 500);
  static const int minParseLength = 3;

  final Dio _dio;
  final String _endpoint;

  Timer? _debounceTimer;
  String? _cachedText;
  VoiceTaskParseResult? _cachedResult;
  int _requestGeneration = 0;

  TextParseService({required Dio dio, required String endpoint})
      : _dio = dio,
        _endpoint = endpoint;

  /// 当前缓存的解析结果（文本完全匹配时有效）。
  VoiceTaskParseResult? cachedResultFor(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed != _cachedText) return null;
    return _cachedResult;
  }

  /// 防抖预解析：输入停顿后后台请求，结果写入缓存。
  void parseTextDebounced(
    String text, {
    void Function(VoiceTaskParseResult? result)? onResult,
  }) {
    final trimmed = text.trim();
    _debounceTimer?.cancel();

    if (trimmed.length < minParseLength) {
      _cachedText = trimmed;
      _cachedResult = null;
      onResult?.call(null);
      return;
    }

    if (trimmed == _cachedText && _cachedResult != null) {
      onResult?.call(_cachedResult);
      return;
    }

    final generation = ++_requestGeneration;
    _debounceTimer = Timer(debounceDuration, () async {
      final result = await parseText(trimmed);
      if (generation != _requestGeneration) return;
      onResult?.call(result);
    });
  }

  void cancelPendingParse() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _requestGeneration++;
  }

  /// 解析文本，返回结构化结果。
  ///
  /// 网络不可用、超时、或解析失败时返回 null（降级信号）。
  Future<VoiceTaskParseResult?> parseText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed == _cachedText && _cachedResult != null) {
      return _cachedResult;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {'text': trimmed},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final result = VoiceTaskParseResult.fromJson(data);
      final sanitized = _sanitizeDueDate(result);

      _cachedText = trimmed;
      _cachedResult = sanitized;
      return sanitized;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  VoiceTaskParseResult _sanitizeDueDate(VoiceTaskParseResult result) {
    if (result.dueDate != null) {
      final minDate = DateTime.now().subtract(const Duration(days: 1));
      if (result.dueDate!.isBefore(minDate)) {
        return VoiceTaskParseResult(
          title: result.title,
          description: result.description,
          dueDate: null,
          priority: result.priority,
          confidence: result.confidence,
          rawTranscript: result.rawTranscript,
          tag: result.tag,
        );
      }
    }
    return result;
  }
}
