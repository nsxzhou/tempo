import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/utils/notification_timezone.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/domain/recurrence_engine.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('todoReminderDateTime', () {
    test('uses actual time for timed task', () {
      final task = Task(
        id: 't1',
        listId: 'inbox',
        title: '锻炼',
        dueDate: DateTime(2026, 6, 25, 20, 0),
        isAllDay: false,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final reminderAt = todoReminderDateTime(task);

      expect(reminderAt, DateTime(2026, 6, 25, 20));
    });

    test('uses calendar day at 08:00 for all-day task', () {
      final task = Task(
        id: 't1',
        listId: 'inbox',
        title: '喝水',
        dueDate: DateTime(2026, 6, 25),
        isAllDay: true,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final reminderAt = todoReminderDateTime(task);

      expect(reminderAt, DateTime(2026, 6, 25, 8));
    });

    test('is not after now when due today and current time past reminder', () {
      final task = Task(
        id: 't1',
        listId: 'inbox',
        title: '锻炼',
        dueDate: DateTime(2026, 6, 25, 8, 0),
        isAllDay: false,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final reminderAt = todoReminderDateTime(task);
      final now = DateTime(2026, 6, 25, 10, 0);

      expect(reminderAt.isAfter(now), isFalse);
    });
  });

  group('reminderAtToZonedDateTime', () {
    setUp(() {
      configureNotificationTimezoneForTest('Asia/Shanghai');
    });

    tearDown(resetNotificationTimezoneForTest);

    test('maps local reminder wall clock into tz.local', () {
      final zoned = reminderAtToZonedDateTime(DateTime(2026, 7, 8, 8));
      expect(zoned.year, 2026);
      expect(zoned.month, 7);
      expect(zoned.day, 8);
      expect(zoned.hour, 8);
      expect(zoned.location, tz.local);
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

  group('NotificationService recurring reminders', () {
    late _FakeIOSNotificationsPlugin platform;
    late NotificationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      configureNotificationTimezoneForTest('Asia/Shanghai');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      platform = _FakeIOSNotificationsPlugin();
      FlutterLocalNotificationsPlatform.instance = platform;
      service = NotificationService();
      await service.setRemindersEnabled(true);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      resetNotificationTimezoneForTest();
    });

    test('uses stable notification ids for the same key', () {
      expect(
        stableNotificationIdForKey('occ:task-1:2026-07-04'),
        stableNotificationIdForKey('occ:task-1:2026-07-04'),
      );
      expect(
        stableNotificationIdForKey('task:task-1'),
        isNot(stableNotificationIdForKey('task:task-2')),
      );
    });

    test(
      'cancelTaskReminders cancels pending legacy payloads for task',
      () async {
        platform.pending.addAll([
          const PendingNotificationRequest(91, '待办提醒', '喝水', 'task-1'),
          const PendingNotificationRequest(92, '待办提醒', '喝水', 'task-1'),
          const PendingNotificationRequest(93, '待办提醒', '读书', 'task-2'),
        ]);

        await service.cancelTaskReminders('task-1');

        expect(platform.cancelledIds, containsAll([91, 92]));
        expect(platform.cancelledIds, isNot(contains(93)));
      },
    );

    test('scheduleTaskReminder skips completed single task', () async {
      final now = DateTime(2026, 7, 9, 7);
      service = NotificationService(now: () => now);
      final task = Task(
        id: 'task-1',
        listId: 'inbox',
        title: '测试提醒',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: true,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await service.scheduleTaskReminder(task);

      expect(platform.scheduled, isEmpty);
      expect(
        platform.cancelledIds,
        contains(stableNotificationIdForKey('task:task-1')),
      );
    });

    test(
      'scheduleTaskReminder does not backfill missed all-day reminder',
      () async {
        final now = DateTime(2026, 7, 9, 10, 50);
        service = NotificationService(now: () => now);
        final task = Task(
          id: 'task-1',
          listId: 'inbox',
          title: '死虫式',
          dueDate: DateTime(2026, 7, 9),
          isAllDay: true,
          createdAt: DateTime(2026, 7, 8),
          updatedAt: DateTime(2026, 7, 8),
        );

        await service.scheduleTaskReminder(task);

        expect(platform.scheduled, isEmpty);
      },
    );

    test(
      'rescheduleAllTasks clears old notifications before rebuilding',
      () async {
        final now = DateTime(2026, 7, 9, 7);
        service = NotificationService(now: () => now);
        platform.pending.addAll([
          const PendingNotificationRequest(91, '待办提醒', '旧提醒', 'old-task'),
          const PendingNotificationRequest(92, '待办提醒', '旧重复', 'old-repeat'),
        ]);
        final task = Task(
          id: 'task-1',
          listId: 'inbox',
          title: '明天提醒',
          dueDate: DateTime(2026, 7, 10),
          isAllDay: true,
          createdAt: now,
          updatedAt: now,
        );

        await service.rescheduleAllTasks([task]);

        final pendingIds = platform.pending.map((request) => request.id);
        expect(pendingIds, isNot(contains(91)));
        expect(pendingIds, isNot(contains(92)));
        expect(platform.scheduled, hasLength(1));
        expect(platform.scheduled.single.scheduledDate.hour, 8);
      },
    );

    test('scheduleRecurringReminders skips completed occurrence', () async {
      final now = DateTime.now();
      final today = RecurrenceEngine.calendarDay(now);
      final task = _recurringTask(
        dueDate: DateTime(today.year, today.month, today.day, 23, 0),
      );

      await service.scheduleRecurringReminders(
        task,
        completions: [
          TaskCompletion(
            taskId: task.id,
            occurrenceDate: today,
            completedAt: now,
          ),
        ],
      );

      final scheduledOccurrenceDates = platform.scheduled
          .map((notification) => jsonDecode(notification.payload!) as Map)
          .map((payload) => payload['occurrenceDate'])
          .toList();

      expect(scheduledOccurrenceDates, isNot(contains(_formatDay(today))));
      expect(
        scheduledOccurrenceDates,
        contains(_formatDay(today.add(const Duration(days: 1)))),
      );
    });

    test('scheduleRecurringReminders only schedules next occurrence', () async {
      final now = DateTime(2026, 7, 10, 8, 0);
      service = NotificationService(now: () => now);
      final task = Task(
        id: 'task-1',
        listId: 'inbox',
        title: '死虫式',
        dueDate: DateTime(2026, 7, 10, 9),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=7',
        recurrenceCount: 7,
        syncPending: true,
        createdAt: now,
        updatedAt: now,
      );

      await service.scheduleRecurringReminders(task);

      expect(platform.scheduled, hasLength(1));
      final payload =
          jsonDecode(platform.scheduled.single.payload!)
              as Map<String, dynamic>;
      expect(payload['occurrenceDate'], '2026-07-10');
    });

    test('synced cloud task does not keep local reminder', () async {
      final now = DateTime(2026, 7, 10, 8);
      service = NotificationService(
        now: () => now,
        cloudRemindersAvailable: () => true,
      );
      final task = Task(
        id: 'task-1',
        listId: 'inbox',
        title: '云端任务',
        dueDate: DateTime(2026, 7, 10, 9),
        syncPending: false,
        createdAt: now,
        updatedAt: now,
      );

      await service.scheduleTaskReminder(task);

      expect(platform.scheduled, isEmpty);
      expect(
        platform.cancelledIds,
        contains(stableNotificationIdForKey('task:task-1')),
      );
    });

    test(
      'scheduleRecurringReminders schedules all-day series at 08:00 local',
      () async {
        final anchor = RecurrenceEngine.calendarDay(
          DateTime.now().add(const Duration(days: 2)),
        );
        final task = Task(
          id: 'task-1',
          listId: 'inbox',
          title: '死虫式',
          dueDate: anchor,
          isAllDay: true,
          recurrenceRule: 'FREQ=DAILY',
          recurrenceCount: 15,
          createdAt: anchor,
          updatedAt: anchor,
        );

        await service.scheduleRecurringReminders(task);

        expect(platform.scheduled, isNotEmpty);
        final first = platform.scheduled.first;
        expect(first.scheduledDate.hour, 8);
        expect(first.scheduledDate.minute, 0);
        expect(first.scheduledDate.location, tz.local);
      },
    );

    test('showRemoteReminder uses stable id and payload', () async {
      await service.showRemoteReminder(
        reminderKey: 'task-1:2026-07-10:2026-07-10T01:00:00.000Z',
        taskId: 'task-1',
        title: '待办提醒',
        body: '死虫式',
        occurrenceDate: '2026-07-10',
        reminderAt: '2026-07-10T01:00:00.000Z',
      );

      expect(platform.shown, hasLength(1));
      final shown = platform.shown.single;
      expect(
        shown.id,
        stableNotificationIdForKey(
          'remote:task-1:2026-07-10:2026-07-10T01:00:00.000Z',
        ),
      );
      final payload = jsonDecode(shown.payload!) as Map<String, dynamic>;
      expect(payload['taskId'], 'task-1');
      expect(payload['occurrenceDate'], '2026-07-10');
    });

    test(
      'scheduleRecurringReminders clears legacy pending before scheduling',
      () async {
        platform.pending.addAll([
          const PendingNotificationRequest(101, '待办提醒', '喝水', 'task-1'),
          const PendingNotificationRequest(102, '待办提醒', '喝水', 'task-1'),
          const PendingNotificationRequest(201, '待办提醒', '读书', 'task-2'),
        ]);

        await service.scheduleRecurringReminders(
          _recurringTask(dueDate: DateTime.now().add(const Duration(days: 1))),
        );

        expect(platform.cancelledIds, containsAll([101, 102]));
        expect(platform.cancelledIds, isNot(contains(201)));
        expect(platform.scheduled, isNotEmpty);
        expect(
          platform.scheduled
              .map(
                (notification) =>
                    taskIdFromNotificationPayload(notification.payload),
              )
              .toSet(),
          {'task-1'},
        );
      },
    );
  });
}

Task _recurringTask({required DateTime dueDate}) {
  return Task(
    id: 'task-1',
    listId: 'inbox',
    title: '喝水',
    dueDate: dueDate,
    recurrenceRule: 'FREQ=DAILY',
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

String _formatDay(DateTime date) {
  final day = RecurrenceEngine.calendarDay(date);
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final datePart = day.day.toString().padLeft(2, '0');
  return '$year-$month-$datePart';
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
}

class _ShownNotification {
  const _ShownNotification({required this.id, required this.payload});

  final int id;
  final String? payload;
}

class _FakeIOSNotificationsPlugin extends IOSFlutterLocalNotificationsPlugin {
  final pending = <PendingNotificationRequest>[];
  final cancelledIds = <int>[];
  final scheduled = <_ScheduledNotification>[];
  final shown = <_ShownNotification>[];

  @override
  Future<bool?> initialize({
    required DarwinInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List.of(pending);
  }

  @override
  Future<void> cancel({required int id}) async {
    cancelledIds.add(id);
    pending.removeWhere((request) => request.id == id);
  }

  @override
  Future<void> cancelAll() async {
    pending.clear();
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    DarwinNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add(_ShownNotification(id: id, payload: payload));
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    DarwinNotificationDetails? notificationDetails,
  }) async {
    scheduled.add(
      _ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      ),
    );
    pending.add(PendingNotificationRequest(id, title, body, payload));
  }
}
