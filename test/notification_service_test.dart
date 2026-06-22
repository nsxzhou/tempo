import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(service.scheduleTaskReminder(task), completes);
    });
  });
}
