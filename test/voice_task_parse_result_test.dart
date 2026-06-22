import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  test('maps backend JSON into current task fields', () {
    final result = VoiceTaskParseResult.fromJson({
      'title': ' 提交设计稿 ',
      'description': '识别内容: 明天下午三点提交设计稿',
      'due_date': '2026-06-19T15:00:00.000+08:00',
      'is_all_day': false,
      'priority': 2,
      'confidence': 0.86,
      'raw_transcript': '明天下午三点提交设计稿，优先级高',
    });

    expect(result.title, '提交设计稿');
    expect(result.description, '识别内容: 明天下午三点提交设计稿');
    expect(result.dueDate, DateTime.parse('2026-06-19T15:00:00.000+08:00'));
    expect(result.isAllDay, isFalse);
    expect(result.priority, TaskPriority.p1);
    expect(result.confidence, 0.86);
    expect(result.canAutoCreate, isTrue);
  });

  test('parses all-day flag from backend JSON', () {
    final result = VoiceTaskParseResult.fromJson({
      'title': '去吃KFC',
      'description': null,
      'due_date': '2026-06-25T00:00:00.000+08:00',
      'is_all_day': true,
      'priority': 0,
      'confidence': 0.9,
      'raw_transcript': '周四去吃KFC',
      'tag': 'life',
    });

    expect(result.isAllDay, isTrue);
    expect(result.tag, 'life');
  });

  test('low confidence parse requires draft confirmation', () {
    final result = VoiceTaskParseResult.fromJson({
      'title': '买咖啡豆',
      'description': null,
      'due_date': null,
      'priority': 'p3',
      'confidence': 0.55,
      'raw_transcript': '买咖啡豆',
    });

    expect(result.priority, TaskPriority.p3);
    expect(result.canAutoCreate, isFalse);
  });

  test('missing confidence is rejected at the boundary', () {
    expect(
      () => VoiceTaskParseResult.fromJson({
        'title': '提交设计稿',
        'raw_transcript': '提交设计稿',
      }),
      throwsFormatException,
    );
  });
}
