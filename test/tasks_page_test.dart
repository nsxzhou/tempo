import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/presentation/tasks_page.dart';

import 'test_fakes.dart';

void main() {
  testWidgets('high confidence voice parse creates task and supports undo', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final recorder = FakeVoiceRecorder();
    final service = FakeVoiceTaskService(result: _voiceResult());

    await _pumpTasksPage(
      tester,
      repository: repository,
      recorder: recorder,
      service: service,
    );

    await _submitVoice(tester);

    expect(recorder.started, isTrue);
    expect(recorder.stopped, isTrue);
    expect(service.parsedFiles, ['/tmp/voice.m4a']);
    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '提交设计稿');
    expect(repository.tasks.single.creationSource, 'voice');
    expect(find.textContaining('已创建语音任务'), findsOneWidget);

    await tester.tap(find.text('撤回'));
    await tester.pump();

    expect(repository.deletedTaskIds, ['task-0']);
    await repository.dispose();
  });

  testWidgets('low confidence voice parse opens editable draft', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final recorder = FakeVoiceRecorder();
    final service = FakeVoiceTaskService(
      result: _voiceResult(confidence: 0.52),
    );

    await _pumpTasksPage(
      tester,
      repository: repository,
      recorder: recorder,
      service: service,
    );

    await _submitVoice(tester);

    expect(repository.tasks, isEmpty);
    expect(find.text('需要确认语音任务'), findsOneWidget);

    await tester.tap(find.text('创建任务'));
    await tester.pump();

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '提交设计稿');
    await repository.dispose();
  });

  testWidgets('backend error does not create a task', (tester) async {
    final repository = FakeTaskRepository();
    final recorder = FakeVoiceRecorder();
    final service = FakeVoiceTaskService(error: StateError('backend 500'));

    await _pumpTasksPage(
      tester,
      repository: repository,
      recorder: recorder,
      service: service,
    );

    await _submitVoice(tester);

    expect(repository.tasks, isEmpty);
    expect(find.textContaining('backend 500'), findsOneWidget);
    await repository.dispose();
  });
}

Future<void> _pumpTasksPage(
  WidgetTester tester, {
  required FakeTaskRepository repository,
  required FakeVoiceRecorder recorder,
  required FakeVoiceTaskService service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        voiceRecorderProvider.overrideWithValue(recorder),
        voiceTaskServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(home: TasksPage()),
    ),
  );
  await tester.pump();
}

Future<void> _submitVoice(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey('voice-fab'))),
  );
  await tester.pump(const Duration(milliseconds: 650));
  await tester.pump();
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

VoiceTaskParseResult _voiceResult({double confidence = 0.86}) {
  return VoiceTaskParseResult(
    title: '提交设计稿',
    description: '识别内容: 明天下午三点提交设计稿，优先级高',
    dueDate: DateTime(2026, 6, 19, 15),
    priority: TaskPriority.p1,
    confidence: confidence,
    rawTranscript: '明天下午三点提交设计稿，优先级高',
  );
}
