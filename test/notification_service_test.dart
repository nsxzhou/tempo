import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('todoReminderDateTime', () {
    test('uses calendar day at 08:00 for timed task', () {
      final dueDate = DateTime(2026, 6, 25, 15, 30);
      final reminderAt = todoReminderDateTime(dueDate);

      expect(reminderAt, DateTime(2026, 6, 25, 8));
    });

    test('uses calendar day at 08:00 for all-day task', () {
      final dueDate = DateTime(2026, 6, 25);
      final reminderAt = todoReminderDateTime(dueDate);

      expect(reminderAt, DateTime(2026, 6, 25, 8));
    });

    test('is not after now when due today and current time past 08:00', () {
      final dueDate = DateTime(2026, 6, 25, 15, 0);
      final reminderAt = todoReminderDateTime(dueDate);
      final now = DateTime(2026, 6, 25, 10, 0);

      expect(reminderAt.isAfter(now), isFalse);
    });
  });

  group('NotificationService preferences', () {
    late NotificationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationService();
    });

    test('isRemindersEnabled defaults to true', () async {
      expect(await service.isRemindersEnabled(), isTrue);
    });

    test('setRemindersEnabled persists preference', () async {
      await service.setRemindersEnabled(false);
      expect(await service.isRemindersEnabled(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.prefNotificationEnabled), isFalse);
    });

    test('scheduleTaskReminder skips when reminders disabled', () async {
      await service.setRemindersEnabled(false);
      final task = Task(
        id: 'task-1',
        listId: 'inbox',
        title: '开会',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(service.scheduleTaskReminder(task), completes);
    });
  });
}
