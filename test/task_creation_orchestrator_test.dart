import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/data/task_ai_enhancement_state.dart';
import 'package:tempo/features/tasks/data/task_creation_orchestrator.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';

import 'test_fakes.dart';

void main() {
  group('TaskCreationOrchestrator', () {
    late FakeTaskRepository repository;
    late FakeTextParseService parseService;
    late _RecordingNotificationService notifications;
    late TaskAiEnhancementController aiEnhancement;
    late List<String> snackbarMessages;
    late TaskCreationOrchestrator orchestrator;

    setUp(() {
      repository = FakeTaskRepository();
      parseService = FakeTextParseService(
        result: VoiceTaskParseResult(
          title: '开会',
          description: null,
          dueDate: DateTime(2026, 6, 20, 15),
          priority: TaskPriority.p1,
          confidence: 0.9,
          rawTranscript: '明天下午三点开会',
          tag: AppConstants.tagWork,
        ),
      );
      notifications = _RecordingNotificationService();
      aiEnhancement = TaskAiEnhancementController();
      snackbarMessages = [];
      orchestrator = TaskCreationOrchestrator(
        repository: repository,
        parseService: parseService,
        notificationService: notifications,
        aiEnhancementTracker: aiEnhancement,
        showSnackbar: ({required message, undoLabel, onUndo}) {
          snackbarMessages.add(message);
        },
      );
    });

    tearDown(() async {
      aiEnhancement.dispose();
      await repository.dispose();
    });

    test(
      'quick create creates raw task first then enhances LLM fields',
      () async {
        parseService.parseDelay = const Duration(milliseconds: 40);

        await orchestrator.enqueueQuickCreate(
          const QuickCreateInput(title: '明天下午三点开会'),
        );

        expect(repository.tasks, hasLength(1));
        expect(repository.tasks.single.title, '明天下午三点开会');
        expect(aiEnhancement.state['task-0'], TaskAiEnhancementStatus.pending);
        expect(snackbarMessages.single, '已创建:明天下午三点开会');

        await _drainBackgroundWork();

        expect(parseService.parseCallCount, 1);
        expect(repository.tasks.single.title, '开会');
        expect(repository.tasks.single.priority, TaskPriority.p1);
        expect(repository.tasks.single.tag, AppConstants.tagWork);
        expect(
          aiEnhancement.state['task-0'],
          TaskAiEnhancementStatus.succeeded,
        );
        expect(notifications.scheduledTaskIds, ['task-0']);
      },
    );

    test('skipParse uses raw title and skips LLM', () async {
      await orchestrator.enqueueQuickCreate(
        const QuickCreateInput(
          title: '明天下午三点开会',
          skipParse: true,
          priority: TaskPriority.p2,
          tag: AppConstants.tagLife,
        ),
      );

      expect(parseService.parseCallCount, 0);
      expect(repository.tasks.single.title, '明天下午三点开会');
      expect(repository.tasks.single.priority, TaskPriority.p2);
      expect(repository.tasks.single.tag, AppConstants.tagLife);
    });

    test('parse failure falls back to raw title', () async {
      parseService.result = null;

      await orchestrator.enqueueQuickCreate(
        const QuickCreateInput(title: '买牛奶'),
      );

      await _drainBackgroundWork();

      expect(repository.tasks.single.title, '买牛奶');
      expect(aiEnhancement.state['task-0'], TaskAiEnhancementStatus.failed);
    });

    test('quick create with date sets isAllDay', () async {
      await orchestrator.enqueueQuickCreate(
        QuickCreateInput(
          title: '买牛奶',
          dueDate: DateTime(2026, 6, 20),
          isAllDay: true,
          skipParse: true,
        ),
      );

      expect(repository.tasks.single.isAllDay, isTrue);
    });

    test('quick create with specific time schedules reminder', () async {
      final dueDate = DateTime.now().add(const Duration(hours: 2));

      await orchestrator.enqueueQuickCreate(
        QuickCreateInput(
          title: '开会',
          dueDate: dueDate,
          isAllDay: false,
          skipParse: true,
        ),
      );

      expect(repository.tasks.single.isAllDay, isFalse);
      expect(repository.tasks.single.dueDate, dueDate);
      expect(notifications.scheduledTaskIds, ['task-0']);
    });

    test('parse result carries isAllDay from LLM', () async {
      parseService.result = VoiceTaskParseResult(
        title: '去吃KFC',
        description: null,
        dueDate: DateTime(2026, 6, 25),
        isAllDay: true,
        priority: TaskPriority.none,
        confidence: 0.9,
        rawTranscript: '周四去吃KFC',
        tag: AppConstants.tagLife,
      );

      await orchestrator.enqueueQuickCreate(
        const QuickCreateInput(title: '周四去吃KFC'),
      );

      await _drainBackgroundWork();

      expect(repository.tasks.single.isAllDay, isTrue);
      expect(repository.tasks.single.tag, AppConstants.tagLife);
    });

    test('voice create uses createVoiceTask path', () async {
      await orchestrator.enqueueVoiceCreate(
        VoiceTaskParseResult(
          title: '提交设计稿',
          description: '识别内容',
          dueDate: DateTime(2026, 6, 19, 15),
          priority: TaskPriority.p1,
          confidence: 0.86,
          rawTranscript: '明天提交设计稿',
        ),
      );

      expect(repository.tasks.single.creationSource, AppConstants.sourceVoice);
      expect(snackbarMessages.single, '已创建语音任务:提交设计稿');
    });

    test('repository failure shows failure snackbar', () async {
      repository.createError = StateError('db down');

      await orchestrator.enqueueQuickCreate(
        const QuickCreateInput(title: '买牛奶', skipParse: true),
      );

      expect(repository.tasks, isEmpty);
      expect(snackbarMessages.single, contains('创建失败'));
    });

    test('voice pipeline auto-creates on high confidence', () async {
      parseService.result = _voiceResult();
      final session = FakeStreamingVoiceSession();

      await orchestrator.enqueueVoicePipeline(
        session: session,
        onNeedDraftConfirm: (_) => fail('should auto create'),
      );

      expect(session.stopped, isTrue);
      expect(repository.tasks, hasLength(1));
      expect(repository.tasks.single.title, '提交设计稿');
      expect(snackbarMessages.last, contains('已创建语音任务'));
      expect(parseService.parseCallCount, 1);
      await session.dispose();
    });

    test('voice pipeline opens draft on low confidence', () async {
      parseService.result = _voiceResult(confidence: 0.5);
      final session = FakeStreamingVoiceSession();
      VoiceTaskParseResult? draft;

      await orchestrator.enqueueVoicePipeline(
        session: session,
        onNeedDraftConfirm: (result) => draft = result,
      );

      expect(session.stopped, isTrue);
      expect(repository.tasks, isEmpty);
      expect(draft, isNotNull);
      expect(draft!.confidence, 0.5);
      await session.dispose();
    });

    test('enhancement does not overwrite user edits', () async {
      parseService.parseDelay = const Duration(milliseconds: 40);

      await orchestrator.enqueueQuickCreate(
        const QuickCreateInput(title: '明天下午三点开会'),
      );

      final created = repository.tasks.single;
      await repository.updateTask(created.copyWith(title: '用户改过标题'));
      await _drainBackgroundWork();

      expect(repository.tasks.single.title, '用户改过标题');
      expect(aiEnhancement.state['task-0'], TaskAiEnhancementStatus.succeeded);
    });
  });
}

Future<void> _drainBackgroundWork() async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
}

VoiceTaskParseResult _voiceResult({double confidence = 0.86}) {
  return VoiceTaskParseResult(
    title: '提交设计稿',
    description: null,
    dueDate: DateTime(2026, 6, 19, 15),
    priority: TaskPriority.p1,
    confidence: confidence,
    rawTranscript: '明天下午三点提交设计稿，优先级高',
  );
}

class _RecordingNotificationService implements NotificationService {
  final List<String> scheduledTaskIds = [];

  @override
  void Function(String taskId)? onNotificationTap;

  @override
  Future<void> cancelTaskReminders(String taskId) async {}

  @override
  Future<void> cancelOccurrenceReminder(
    String taskId,
    DateTime occurrenceDate,
  ) async {}

  @override
  Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null || task.isCompleted) return;
    scheduledTaskIds.add(task.id);
  }

  @override
  Future<void> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    if (task.dueDate == null || task.isCompleted) return;
    scheduledTaskIds.add(task.id);
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> isRemindersEnabled() async => true;

  @override
  Future<void> setRemindersEnabled(bool enabled) async {}

  @override
  Future<void> rescheduleAllTasks(Iterable<Task> tasks) async {
    for (final task in tasks) {
      await scheduleTaskReminder(task);
    }
  }
}
