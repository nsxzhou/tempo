// ============================================================
// VoiceTaskService 单元测试
// 覆盖: 正常解析 / 404 / 超时 / 服务端错误
// ============================================================

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/data/voice_task_service.dart';
import 'package:tempo/features/tasks/domain/task.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('DioVoiceTaskService', () {
    late _MockDio dio;
    late DioVoiceTaskService service;

    setUp(() {
      dio = _MockDio();
      when(() => dio.options).thenReturn(BaseOptions());
      when(() => dio.close()).thenAnswer((_) async {});
      service = DioVoiceTaskService(
        dio: dio,
        endpoint: 'https://example.supabase.co/functions/v1/parse-task',
      );
    });

    test('正常解析返回 VoiceTaskParseResult', () async {
      final responseData = {
        'title': '提交设计稿',
        'description': null,
        'due_date':
            DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(),
        'priority': 0,
        'confidence': 0.9,
        'raw_transcript': '明天下午三点提交设计稿',
        'tag': null,
      };

      _setupDioPost(dio, responseData, 200);

      final result = await service.parseAudioBytes(Uint8List.fromList([1, 2, 3]));

      expect(result.title, '提交设计稿');
      expect(result.confidence, 0.9);
      expect(result.priority, TaskPriority.none);
    });

    test('404 映射为 VoiceTaskException', () async {
      when(() => dio.post<Object?>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => service.parseAudioBytes(Uint8List.fromList([1])),
        throwsA(
          isA<VoiceTaskException>().having(
            (e) => e.message,
            'message',
            contains('语音解析服务未就绪'),
          ),
        ),
      );
    });

    test('超时映射为 VoiceTaskException', () async {
      when(() => dio.post<Object?>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
      ));

      expect(
        () => service.parseAudioBytes(Uint8List.fromList([1])),
        throwsA(
          isA<VoiceTaskException>().having(
            (e) => e.message,
            'message',
            contains('超时'),
          ),
        ),
      );
    });

    test('5xx 映射为 VoiceTaskException', () async {
      when(() => dio.post<Object?>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => service.parseAudioBytes(Uint8List.fromList([1])),
        throwsA(
          isA<VoiceTaskException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('5xx 优先展示服务端 error 字段', () async {
      when(() => dio.post<Object?>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          data: {
            'error': 'ASR submit failed: code=45000010, msg=Invalid X-Api-Key',
          },
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => service.parseAudioBytes(Uint8List.fromList([1])),
        throwsA(
          isA<VoiceTaskException>().having(
            (e) => e.message,
            'message',
            contains('Invalid X-Api-Key'),
          ),
        ),
      );
    });
  });
}

void _setupDioPost(_MockDio dio, Map<String, dynamic> data, int statusCode) {
  final response = Response<Object?>(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );

  when(() => dio.post<Object?>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => response);
}
