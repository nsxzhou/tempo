// ============================================================
// TextParseService 单元测试
// 覆盖: 正常解析 / 网络异常降级 / 空响应
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo/features/tasks/data/text_parse_service.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/domain/task.dart';

class _MockDio extends Mock implements Dio {}

class _MockAdapter extends Mock implements HttpClientAdapter {}

void main() {
  group('TextParseService', () {
    late _MockDio dio;
    late TextParseService service;

    setUp(() {
      dio = _MockDio();
      when(() => dio.options).thenReturn(BaseOptions());
      when(() => dio.close()).thenAnswer((_) async {});
      service = TextParseService(
        dio: dio,
        endpoint: 'http://localhost:54321/functions/v1/parse-task',
      );
    });

    test('正常解析返回 VoiceTaskParseResult', () async {
      // 模拟成功响应
      final responseData = {
        'title': '开会',
        'description': null,
        'due_date':
            DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(),
        'priority': 0,
        'confidence': 0.9,
        'raw_transcript': '明天下午三点开会',
      };

      _setupDioPost(dio, responseData, 200);

      final result = await service.parseText('明天下午三点开会');

      expect(result, isNotNull);
      expect(result!.title, '开会');
      expect(result.confidence, 0.9);
      expect(result.priority, TaskPriority.none);
      expect(result.dueDate, isNotNull);
    });

    test('网络异常返回 null（降级信号）', () async {
      when(() => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await service.parseText('明天开会');

      expect(result, isNull);
    });

    test('空文本返回 null', () async {
      final result = await service.parseText('');

      expect(result, isNull);
    });

    test('空响应体返回 null', () async {
      _setupDioPost(dio, null, 200);

      final result = await service.parseText('写周报');

      expect(result, isNull);
    });

    test('不合理的 dueDate（早于当前时间-1天）被清除', () async {
      final pastDate = DateTime.now()
          .subtract(const Duration(days: 3))
          .toUtc()
          .toIso8601String();

      final responseData = {
        'title': '旧任务',
        'description': null,
        'due_date': pastDate,
        'priority': 0,
        'confidence': 0.8,
        'raw_transcript': '三天前开会',
      };

      _setupDioPost(dio, responseData, 200);

      final result = await service.parseText('三天前开会');

      expect(result, isNotNull);
      expect(result!.dueDate, isNull);
    });

    test('无日期信息的文本正常创建任务 dueDate 为 null', () async {
      final responseData = {
        'title': '写周报',
        'description': null,
        'due_date': null,
        'priority': 0,
        'confidence': 0.95,
        'raw_transcript': '写周报',
      };

      _setupDioPost(dio, responseData, 200);

      final result = await service.parseText('写周报');

      expect(result, isNotNull);
      expect(result!.title, '写周报');
      expect(result.dueDate, isNull);
    });

    test('解析优先级关键词', () async {
      final responseData = {
        'title': '紧急修复',
        'description': null,
        'due_date': null,
        'priority': 1,
        'confidence': 0.88,
        'raw_transcript': '紧急修复 bug',
      };

      _setupDioPost(dio, responseData, 200);

      final result = await service.parseText('紧急修复 bug');

      expect(result, isNotNull);
      expect(result!.priority, TaskPriority.p0);
    });
  });
}

/// 设置 Dio post mock 返回值。
void _setupDioPost(_MockDio dio, Map<String, dynamic>? data, int statusCode) {
  final response = Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );

  when(() => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => response);
}
