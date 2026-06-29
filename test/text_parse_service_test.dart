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
        'due_date': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
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
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

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

    test('parseTextDebounced 命中缓存后不再重复请求', () async {
      final responseData = {
        'title': '开会',
        'description': null,
        'due_date': null,
        'priority': 0,
        'confidence': 0.9,
        'raw_transcript': '明天下午三点开会',
      };
      _setupDioPost(dio, responseData, 200);

      VoiceTaskParseResult? debounced;
      service.parseTextDebounced('明天下午三点开会', onResult: (r) => debounced = r);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(debounced, isNotNull);

      clearInteractions(dio);
      final cached = await service.parseText('明天下午三点开会');
      expect(cached, isNotNull);
      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('cachedResultFor 返回最近一次解析', () async {
      final responseData = {
        'title': '写周报',
        'description': null,
        'due_date': null,
        'priority': 0,
        'confidence': 0.95,
        'raw_transcript': '写周报',
      };
      _setupDioPost(dio, responseData, 200);
      await service.parseText('写周报');
      expect(service.cachedResultFor('写周报')?.title, '写周报');
      expect(service.cachedResultFor('其他'), isNull);
    });

    test('parseTextImmediate cancels debounce and parses once', () async {
      final responseData = {
        'title': '开会',
        'description': null,
        'due_date': null,
        'priority': 0,
        'confidence': 0.9,
        'raw_transcript': '明天下午三点开会',
      };
      _setupDioPost(dio, responseData, 200);

      service.parseTextDebounced('明天下午三点开会');
      final result = await service.parseTextImmediate('明天下午三点开会');

      expect(result?.title, '开会');
      verify(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('LRU cache keeps last five entries', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        final data =
            invocation.namedArguments[#data] as Map<String, dynamic>;
        final text = data['text'] as String;
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'title': text,
            'description': null,
            'due_date': null,
            'priority': 0,
            'confidence': 0.9,
            'raw_transcript': text,
          },
        );
      });

      for (var i = 0; i < 6; i++) {
        await service.parseText('文本$i');
      }

      expect(service.cachedResultFor('文本0'), isNull);
      expect(service.cachedResultFor('文本5')?.title, '文本5');
    });

    test(
      'parseTextImmediate reuses prefix cache from debounced partial',
      () async {
        final partialResponse = {
          'title': '开会',
          'description': null,
          'due_date': null,
          'priority': 0,
          'confidence': 0.9,
          'raw_transcript': '明天下午三点开',
        };
        _setupDioPost(dio, partialResponse, 200);

        service.parseTextDebounced('明天下午三点开');
        await Future<void>.delayed(const Duration(milliseconds: 500));

        clearInteractions(dio);
        final result = await service.parseTextImmediate('明天下午三点开会');

        expect(result?.title, '开会');
        verifyNever(
          () => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
      },
    );

    test(
      'parseTextSoft timeout returns null and late result fills cache',
      () async {
        final responseData = {
          'title': '开会',
          'description': null,
          'due_date': null,
          'priority': 0,
          'confidence': 0.9,
          'raw_transcript': '明天下午三点开会',
        };

        final response = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        );
        when(
          () => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return response;
        });

        final result = await service.parseTextSoft(
          '明天下午三点开会',
          timeout: const Duration(milliseconds: 10),
        );
        expect(result, isNull);

        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(service.cachedResultFor('明天下午三点开会')?.title, '开会');
      },
    );
  });
}

/// 设置 Dio post mock 返回值。
void _setupDioPost(_MockDio dio, Map<String, dynamic>? data, int statusCode) {
  final response = Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );

  when(
    () => dio.post<Map<String, dynamic>>(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
    ),
  ).thenAnswer((_) async => response);
}
