// ============================================================
// TextParseService — 文本 LLM 解析服务
// 调用 parse-task Edge Function JSON 路径，支持防抖预解析与缓存
// ============================================================

import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

import 'voice_task_parse_result.dart';

/// 文本 LLM 解析服务。
///
/// 调用 parse-task Edge Function 的 JSON 文本路径，
/// 将自然语言文本解析为结构化任务字段（标题/日期/优先级/tag）。
class TextParseService {
  static const Duration debounceDuration = Duration(milliseconds: 400);
  static const Duration softTimeoutDuration = Duration(seconds: 2);
  static const int minParseLength = 3;
  static const int cacheCapacity = 5;
  static const int _maxFuzzyDistance = 2;

  final Dio _dio;
  final String _endpoint;

  Timer? _debounceTimer;
  final LinkedHashMap<String, VoiceTaskParseResult> _cache =
      LinkedHashMap<String, VoiceTaskParseResult>();
  int _requestGeneration = 0;
  String? _inFlightText;
  Future<VoiceTaskParseResult?>? _inFlightFuture;
  String? _lastDebouncedText;

  TextParseService({required Dio dio, required String endpoint})
    : _dio = dio,
      _endpoint = endpoint;

  /// 当前缓存的解析结果（文本完全匹配时有效）。
  VoiceTaskParseResult? cachedResultFor(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return _cache[trimmed];
  }

  /// 防抖预解析：输入停顿后后台请求，结果写入缓存。
  void parseTextDebounced(
    String text, {
    void Function(VoiceTaskParseResult? result)? onResult,
  }) {
    final trimmed = text.trim();
    _debounceTimer?.cancel();

    if (trimmed.length < minParseLength) {
      onResult?.call(null);
      return;
    }

    _lastDebouncedText = trimmed;

    final cached = cachedResultFor(trimmed);
    if (cached != null) {
      onResult?.call(cached);
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

  /// 取消防抖并立即解析（语音停止时使用）。
  Future<VoiceTaskParseResult?> parseTextImmediate(String text) {
    cancelPendingParse();
    return flushParse(text);
  }

  /// 若有同文本 in-flight 请求则复用，否则立即请求。
  Future<VoiceTaskParseResult?> flushParse(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final cached =
        cachedResultFor(trimmed) ?? _findSimilarCachedResult(trimmed);
    if (cached != null) {
      return _withRawTranscript(cached, trimmed);
    }

    if (_inFlightText == trimmed && _inFlightFuture != null) {
      return _inFlightFuture;
    }

    _inFlightText = trimmed;
    _inFlightFuture = parseText(trimmed);
    try {
      return await _inFlightFuture;
    } finally {
      if (_inFlightText == trimmed) {
        _inFlightText = null;
        _inFlightFuture = null;
      }
    }
  }

  /// 解析文本，返回结构化结果。
  ///
  /// 网络不可用、超时、或解析失败时返回 null（降级信号）。
  Future<VoiceTaskParseResult?> parseText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final cached = _cache[trimmed];
    if (cached != null) return cached;

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
      _rememberCache(trimmed, sanitized);
      return sanitized;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<VoiceTaskParseResult?> parseTextSoft(
    String text, {
    Duration timeout = softTimeoutDuration,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final cached =
        cachedResultFor(trimmed) ?? _findSimilarCachedResult(trimmed);
    if (cached != null) return _withRawTranscript(cached, trimmed);

    final parseFuture = parseText(trimmed);
    try {
      return await parseFuture.timeout(timeout);
    } on TimeoutException {
      unawaited(parseFuture.then<void>((_) {}));
      return null;
    }
  }

  VoiceTaskParseResult? _findSimilarCachedResult(String trimmed) {
    for (final entry in _cache.entries.toList().reversed) {
      if (_isSimilarText(entry.key, trimmed)) {
        return _withRawTranscript(entry.value, trimmed);
      }
    }

    final lastDebounced = _lastDebouncedText;
    if (lastDebounced != null && _isSimilarText(lastDebounced, trimmed)) {
      final lastResult = _cache[lastDebounced];
      if (lastResult != null) {
        return _withRawTranscript(lastResult, trimmed);
      }
    }

    return null;
  }

  bool _isSimilarText(String left, String right) {
    if (left == right) return true;
    if (left.startsWith(right) || right.startsWith(left)) return true;
    return _levenshtein(left, right) <= _maxFuzzyDistance;
  }

  VoiceTaskParseResult _withRawTranscript(
    VoiceTaskParseResult result,
    String transcript,
  ) {
    if (result.rawTranscript.trim() == transcript) return result;
    return result.copyWith(rawTranscript: transcript);
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((value, element) => value < element ? value : element);
      }
    }

    return matrix[a.length][b.length];
  }

  void _rememberCache(String key, VoiceTaskParseResult result) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    _cache[key] = result;
    while (_cache.length > cacheCapacity) {
      _cache.remove(_cache.keys.first);
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
          isAllDay: result.isAllDay,
          priority: result.priority,
          confidence: result.confidence,
          rawTranscript: result.rawTranscript,
          tag: result.tag,
          recurrenceRule: result.recurrenceRule,
          recurrenceEnd: result.recurrenceEnd,
          recurrenceCount: result.recurrenceCount,
          durationMin: result.durationMin,
        );
      }
    }
    return result;
  }
}
