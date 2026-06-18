// ============================================================
// TextParseService — 文本 LLM 解析服务
// 调用 parse-task Edge Function 文本路径，离线降级返回 null
// ============================================================

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import 'voice_task_parse_result.dart';

/// 文本 LLM 解析服务。
///
/// 调用 parse-task Edge Function 的 JSON 文本路径，
/// 将自然语言文本解析为结构化任务字段（标题/日期/优先级）。
///
/// 网络不可用或解析失败时返回 null，触发 UI 降级为手动 DatePicker。
class TextParseService {
  final Dio _dio;
  final String _endpoint;

  TextParseService({required Dio dio, required String endpoint})
      : _dio = dio,
        _endpoint = endpoint;

  /// 解析文本，返回结构化结果。
  ///
  /// 网络不可用、超时、或解析失败时返回 null（降级信号）。
  Future<VoiceTaskParseResult?> parseText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

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

      // 合理性校验：dueDate 不应早于当前时间 -1 天
      if (result.dueDate != null) {
        final minDate = DateTime.now().subtract(const Duration(days: 1));
        if (result.dueDate!.isBefore(minDate)) {
          // 日期不合理，返回不带日期的结果
          return result.copyWith(dueDate: null);
        }
      }

      return result;
    } on DioException catch (_) {
      // 网络错误/超时 → 降级
      return null;
    } catch (_) {
      // 解析错误 → 降级
      return null;
    }
  }
}
