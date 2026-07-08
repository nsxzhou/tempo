// ============================================================
// NotificationService — 本地待办提醒调度
// 单次任务：1 条通知；重复任务：预调度未来 N 次 occurrence
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/notification_timezone.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/task_filter.dart';
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';

/// 计算待办提醒时刻：全天 → 08:00；否则用 due 实际时分
DateTime todoReminderDateTime(Task task, [DateTime? occurrenceDue]) {
  final due = occurrenceDue ?? task.dueDate;
  if (due == null) return DateTime.now();
  if (task.isAllDay) {
    return DateTime(due.year, due.month, due.day, 8);
  }
  return due;
}

@visibleForTesting
int stableNotificationIdForKey(String key) {
  const fnvOffset = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  var hash = fnvOffset;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

@visibleForTesting
String? taskIdFromNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      final taskId = decoded['taskId'];
      if (taskId is String && taskId.isNotEmpty) return taskId;
    }
  } catch (_) {
    // Legacy payloads were the raw task id.
  }
  return payload;
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final RecurrenceEngine _engine;
  bool _initialized = false;
  static SharedPreferences? _prefsCache;

  static const _recurringHorizon = 14;

  static Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  void Function(String taskId)? onNotificationTap;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    RecurrenceEngine? engine,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _engine = engine ?? const RecurrenceEngine();

  Future<void> init() async {
    if (_initialized) return;

    await configureNotificationTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createAndroidChannel();

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationsGranted = await android
          ?.requestNotificationsPermission();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact != true) {
        await android?.requestExactAlarmsPermission();
      }
      return notificationsGranted ?? false;
    }

    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return iosResult ?? true;
  }

  Future<bool> isRemindersEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(AppConstants.prefNotificationEnabled) ?? true;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(AppConstants.prefNotificationEnabled, enabled);
    if (!enabled) {
      try {
        await cancelAll();
      } catch (e, stack) {
        _debugPrintNotificationFailure(
          'cancelAll failed when disabling reminders',
          e,
          stack,
        );
      }
    }
  }

  Future<void> rescheduleAllTasks(
    Iterable<Task> tasks, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    if (!await isRemindersEnabled()) return;
    for (final task in tasks) {
      unawaited(
        scheduleTaskReminder(
          task,
          completions: completions.forTask(task.id, (c) => c.taskId),
          exceptions: exceptions.forTask(task.id, (e) => e.taskId),
        ),
      );
    }
  }

  Future<void> scheduleTaskReminder(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    if (task.isRecurring) {
      await scheduleRecurringReminders(
        task,
        completions: completions,
        exceptions: exceptions,
      );
      return;
    }
    await _scheduleSingle(task, task.dueDate, task.id);
  }

  Future<void> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    try {
      if (!_initialized) await init();
      if (!await isRemindersEnabled()) return;
      if (!task.isRecurring) return;

      await cancelTaskReminders(task.id);

      final now = DateTime.now();
      final fromDay = RecurrenceEngine.calendarDay(now);
      final occs = _engine.expandOccurrences(
        task,
        from: fromDay,
        to: fromDay.add(const Duration(days: 60)),
        completions: completions,
        exceptions: exceptions,
        now: now,
      );

      var scheduled = 0;
      for (final occ in occs) {
        if (occ.state != OccurrenceState.pending) continue;
        if (scheduled >= _recurringHorizon) break;
        await _scheduleSingle(
          task,
          occ.effectiveDue,
          task.id,
          occurrenceDate: occ.occurrenceDate,
        );
        scheduled++;
      }
    } catch (e, stack) {
      _debugPrintNotificationFailure(
        'scheduleRecurringReminders failed for ${task.id}',
        e,
        stack,
      );
    }
  }

  Future<void> cancelOccurrenceReminder(
    String taskId,
    DateTime occurrenceDate,
  ) async {
    await _safeCancel(_occurrenceNotificationId(taskId, occurrenceDate));
    await _cancelPendingWhere(
      (request) =>
          taskIdFromNotificationPayload(request.payload) == taskId &&
          _occurrenceDateFromNotificationPayload(request.payload) ==
              _formatCalendarDay(occurrenceDate),
    );
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await _safeCancel(_notificationId(taskId));
    await _cancelPendingWhere(
      (request) => taskIdFromNotificationPayload(request.payload) == taskId,
    );
    // 兼容无法读取 pending notification 的平台：仍尝试取消当前稳定 ID 窗口。
    for (var i = 0; i < _recurringHorizon; i++) {
      final day = DateTime.now().add(Duration(days: i));
      await _safeCancel(_occurrenceNotificationId(taskId, day));
    }
  }

  Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      // 对不存在通知 ID 的取消操作静默忽略
      debugPrint('[Tempo] cancel($id) ignored: $e');
    }
  }

  Future<void> _cancelPendingWhere(
    bool Function(PendingNotificationRequest request) matches,
  ) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (matches(request)) {
          await _safeCancel(request.id);
        }
      }
    } catch (e) {
      debugPrint('[Tempo] pendingNotificationRequests ignored: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _scheduleSingle(
    Task task,
    DateTime? due,
    String payloadTaskId, {
    DateTime? occurrenceDate,
  }) async {
    try {
      if (!_initialized) await init();
      if (!await isRemindersEnabled()) return;
      if (due == null) return;

      final now = DateTime.now();
      final reminderAt = todoReminderDateTime(task, due);
      if (!reminderAt.isAfter(now)) return;

      final id = occurrenceDate != null
          ? _occurrenceNotificationId(payloadTaskId, occurrenceDate)
          : _notificationId(payloadTaskId);

      await _zonedSchedule(
        id: id,
        title: '待办提醒',
        body: task.title,
        scheduledTime: reminderAt,
        payload: _notificationPayload(payloadTaskId, occurrenceDate),
      );
    } catch (e, stack) {
      _debugPrintNotificationFailure(
        'schedule reminder failed for $payloadTaskId',
        e,
        stack,
      );
    }
  }

  void _debugPrintNotificationFailure(
    String operation,
    Object error,
    StackTrace stack,
  ) {
    if (!kDebugMode || error.toString().contains('LateInitializationError')) {
      return;
    }
    debugPrint('[Tempo] $operation: $error');
    debugPrintStack(stackTrace: stack);
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = reminderAtToZonedDateTime(scheduledTime);
    final androidScheduleMode = await _androidScheduleMode();

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: androidScheduleMode,
      title: title,
      body: body,
      payload: payload,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    final taskId = taskIdFromNotificationPayload(response.payload);
    if (taskId != null && onNotificationTap != null) {
      onNotificationTap!(taskId);
    }
  }

  int _notificationId(String taskId) =>
      stableNotificationIdForKey('task:$taskId');

  int _occurrenceNotificationId(String taskId, DateTime occurrenceDate) {
    return stableNotificationIdForKey(
      'occ:$taskId:${_formatCalendarDay(occurrenceDate)}',
    );
  }

  String _notificationPayload(String taskId, DateTime? occurrenceDate) {
    final payload = <String, Object?>{'v': 1, 'taskId': taskId};
    if (occurrenceDate != null) {
      payload['occurrenceDate'] = _formatCalendarDay(occurrenceDate);
    }
    return jsonEncode(payload);
  }

  String _formatCalendarDay(DateTime date) {
    final day = RecurrenceEngine.calendarDay(date);
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final datePart = day.day.toString().padLeft(2, '0');
    return '$year-$month-$datePart';
  }

  String? _occurrenceDateFromNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final occurrenceDate = decoded['occurrenceDate'];
        if (occurrenceDate is String && occurrenceDate.isNotEmpty) {
          return occurrenceDate;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
