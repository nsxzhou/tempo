import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/app.dart';
import 'package:tempo/app_providers.dart';

import 'test_fakes.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          streamingVoiceSessionProvider.overrideWithValue(
            FakeStreamingVoiceSession(),
          ),
          textParseServiceProvider.overrideWithValue(FakeTextParseService()),
          notificationServiceProvider.overrideWithValue(
            _NoopNotificationService(),
          ),
        ],
        child: const TempoApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(TempoApp), findsOneWidget);
    await repository.dispose();
  });
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> cancelTaskReminders(String taskId) async {}

  @override
  Future<void> cancelOccurrenceReminder(
    String taskId,
    DateTime occurrenceDate,
  ) async {}

  @override
  Future<void> scheduleTaskReminder(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {}

  @override
  Future<void> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> rescheduleAllTasks(
    Iterable<Task> tasks, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {}
}
