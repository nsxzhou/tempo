// ============================================================
// NotificationService — 本地待办提醒调度
// 单次任务：1 条通知；重复任务：滚动预排未来 90 天 occurrence
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/task_filter.dart';
import '../../../core/utils/notification_timezone.dart';
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';

/// 计算待办提醒时刻：全天 → 08:00；否则用 due 实际时分。
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
AndroidScheduleMode androidScheduleModeForCapability(bool exactAlarmsAllowed) {
  return exactAlarmsAllowed
      ? AndroidScheduleMode.alarmClock
      : AndroidScheduleMode.inexactAllowWhileIdle;
}

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

class NotificationCapability {
  const NotificationCapability({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    this.channelEnabled = true,
  });

  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
  final bool channelEnabled;

  bool get isFullyAvailable =>
      notificationsAllowed && exactAlarmsAllowed && channelEnabled;
}

enum ReminderScheduleStatus {
  scheduled,
  scheduledInexact,
  skippedPast,
  skippedCompleted,
  notificationsDenied,
  channelDisabled,
  pendingVerificationFailed,
  platformFailure,
}

class ReminderScheduleResult {
  const ReminderScheduleResult({
    required this.status,
    this.taskId,
    this.notificationId,
    this.scheduledAt,
    this.error,
  });

  final ReminderScheduleStatus status;
  final String? taskId;
  final int? notificationId;
  final DateTime? scheduledAt;
  final String? error;

  bool get isSuccess =>
      status == ReminderScheduleStatus.scheduled ||
      status == ReminderScheduleStatus.scheduledInexact;
  bool get needsAttention =>
      !isSuccess &&
      status != ReminderScheduleStatus.skippedPast &&
      status != ReminderScheduleStatus.skippedCompleted;
}

class ReminderDiagnostics {
  const ReminderDiagnostics({
    required this.now,
    required this.timezoneName,
    required this.capability,
    required this.pendingCount,
    this.lastResult,
  });

  final DateTime now;
  final String timezoneName;
  final NotificationCapability capability;
  final int pendingCount;
  final ReminderScheduleResult? lastResult;
}

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    RecurrenceEngine? engine,
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _engine = engine ?? const RecurrenceEngine(),
       _now = now ?? DateTime.now;

  static const _settingsChannel = MethodChannel(
    'com.tempo.tempo/notifications',
  );
  static const _localReminderSchemaKey = 'local_reminder_schema_version';
  static const _localReminderSchemaVersion = 1;
  static const recurringScheduleHorizon = Duration(days: 90);
  static const _cancelLookbackDays = 60;
  static const _cancelLookaheadDays = 120;

  final FlutterLocalNotificationsPlugin _plugin;
  final RecurrenceEngine _engine;
  final DateTime Function() _now;
  bool _initialized = false;
  ReminderScheduleResult? _lastResult;
  Future<void> _mutationTail = Future<void>.value();

  void Function(String taskId)? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    await configureNotificationTimezone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher_monochrome'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _createAndroidChannel();
    _initialized = true;
  }

  /// 新版首次启动清理 FCM 时代和旧重复策略留下的排程。
  Future<void> prepareLocalOnlyScheduling() async {
    await _serialize(() async {
      if (!_initialized) await init();
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_localReminderSchemaKey) ?? 0;
      if (version >= _localReminderSchemaVersion) return;
      await _plugin.cancelAll();
      await prefs.setInt(_localReminderSchemaKey, _localReminderSchemaVersion);
    });
  }

  /// 只申请通知展示权限；精确闹钟设置通过任务页提示按需打开。
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    if (Platform.isAndroid) {
      final android = _androidPlugin;
      return await android?.requestNotificationsPermission() ?? false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
  }

  Future<NotificationCapability> capability() async {
    if (!_initialized) await init();
    if (!Platform.isAndroid) {
      return const NotificationCapability(
        notificationsAllowed: true,
        exactAlarmsAllowed: true,
      );
    }
    final android = _androidPlugin;
    final channels = await android?.getNotificationChannels();
    AndroidNotificationChannel? reminderChannel;
    for (final channel in channels ?? const <AndroidNotificationChannel>[]) {
      if (channel.id == AppConstants.notificationChannelId) {
        reminderChannel = channel;
        break;
      }
    }
    return NotificationCapability(
      notificationsAllowed: await android?.areNotificationsEnabled() ?? false,
      exactAlarmsAllowed:
          await android?.canScheduleExactNotifications() ?? false,
      channelEnabled:
          reminderChannel != null &&
          reminderChannel.importance != Importance.none,
    );
  }

  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    await _settingsChannel.invokeMethod<void>('openNotificationSettings');
  }

  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    await _settingsChannel.invokeMethod<void>('openExactAlarmSettings');
  }

  Future<void> openBackgroundSettings() async {
    if (!Platform.isAndroid) return;
    await _settingsChannel.invokeMethod<void>('openBackgroundSettings');
  }

  Future<int> pendingNotificationCount() async {
    if (!_initialized) await init();
    return (await _plugin.pendingNotificationRequests()).length;
  }

  /// 串行重建当前快照中所有任务的提醒，防止与创建/编辑并发互相取消。
  Future<void> rescheduleAllTasks(
    Iterable<Task> tasks, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) {
    final snapshot = List<Task>.unmodifiable(tasks);
    return _serialize(() async {
      if (!_initialized) await init();
      for (final task in snapshot) {
        await _cancelTaskReminders(task.id);
        await _scheduleTaskReminder(
          task,
          completions: completions.forTask(task.id, (c) => c.taskId),
          exceptions: exceptions.forTask(task.id, (e) => e.taskId),
        );
      }
    });
  }

  Future<ReminderScheduleResult> scheduleTaskReminder(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) {
    return _serializeResult(() async {
      if (!_initialized) await init();
      await _cancelTaskReminders(task.id);
      if (task.isCompleted || task.dueDate == null) {
        return _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.skippedCompleted,
            taskId: task.id,
          ),
        );
      }
      if (task.isRecurring) {
        return _scheduleRecurringReminders(
          task,
          completions: completions,
          exceptions: exceptions,
        );
      }
      return _scheduleSingle(task, task.dueDate, task.id);
    });
  }

  Future<void> _scheduleTaskReminder(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    if (task.isCompleted || task.dueDate == null) return;
    if (task.isRecurring) {
      await _scheduleRecurringReminders(
        task,
        completions: completions,
        exceptions: exceptions,
      );
      return;
    }
    await _scheduleSingle(task, task.dueDate, task.id);
  }

  Future<ReminderScheduleResult> _scheduleRecurringReminders(
    Task task, {
    required List<TaskCompletion> completions,
    required List<RecurrenceException> exceptions,
  }) async {
    final now = _now();
    final occurrences = _engine.expandOccurrences(
      task,
      from: RecurrenceEngine.calendarDay(now),
      to: RecurrenceEngine.calendarDay(now.add(recurringScheduleHorizon)),
      completions: completions,
      exceptions: exceptions,
      now: now,
    );
    final horizonEnd = now.add(recurringScheduleHorizon);
    ReminderScheduleResult? lastScheduled;
    for (final occurrence in occurrences) {
      if (occurrence.state != OccurrenceState.pending) continue;
      final reminderAt = todoReminderDateTime(task, occurrence.effectiveDue);
      if (reminderAt.isAfter(horizonEnd)) continue;
      final result = await _scheduleSingle(
        task,
        occurrence.effectiveDue,
        task.id,
        occurrenceDate: occurrence.occurrenceDate,
        body: occurrence.title,
      );
      if (result.needsAttention) return result;
      if (result.isSuccess) lastScheduled = result;
    }
    return lastScheduled ??
        _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.skippedPast,
            taskId: task.id,
          ),
        );
  }

  Future<ReminderScheduleResult> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) {
    return _serializeResult(() async {
      if (!_initialized) await init();
      await _cancelTaskReminders(task.id);
      if (task.isCompleted || task.dueDate == null || !task.isRecurring) {
        return _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.skippedCompleted,
            taskId: task.id,
          ),
        );
      }
      return _scheduleRecurringReminders(
        task,
        completions: completions,
        exceptions: exceptions,
      );
    });
  }

  Future<void> cancelOccurrenceReminder(
    String taskId,
    DateTime occurrenceDate,
  ) {
    return _serialize(() async {
      await _safeCancel(_occurrenceNotificationId(taskId, occurrenceDate));
      await _cancelPendingWhere(
        (request) =>
            taskIdFromNotificationPayload(request.payload) == taskId &&
            _occurrenceDateFromNotificationPayload(request.payload) ==
                _formatCalendarDay(occurrenceDate),
      );
    });
  }

  Future<void> cancelTaskReminders(String taskId) {
    return _serialize(() => _cancelTaskReminders(taskId));
  }

  Future<void> _cancelTaskReminders(String taskId) async {
    await _safeCancel(_notificationId(taskId));
    final pendingRead = await _cancelPendingWhere(
      (request) => taskIdFromNotificationPayload(request.payload) == taskId,
    );
    if (pendingRead) return;

    // 仅在平台无法读取 pending notification 时按稳定 ID 清理遗留 occurrence。
    final today = RecurrenceEngine.calendarDay(_now());
    for (var i = -_cancelLookbackDays; i <= _cancelLookaheadDays; i++) {
      await _safeCancel(
        _occurrenceNotificationId(taskId, today.add(Duration(days: i))),
      );
    }
  }

  ReminderScheduleResult _recordResult(ReminderScheduleResult result) {
    _lastResult = result;
    return result;
  }

  Future<ReminderDiagnostics> diagnostics() async {
    if (!_initialized) await init();
    return ReminderDiagnostics(
      now: _now(),
      timezoneName: tz.local.name,
      capability: await capability(),
      pendingCount: (await _plugin.pendingNotificationRequests()).length,
      lastResult: _lastResult,
    );
  }

  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    await _plugin.show(
      id: stableNotificationIdForKey('tempo:test:immediate'),
      title: 'Tempo 通知测试',
      body: '如果你看到这条通知，通知渠道可以正常展示。',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher_monochrome',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<ReminderScheduleResult> scheduleTestReminder({
    Duration delay = const Duration(minutes: 2),
  }) async {
    final now = _now();
    final task = Task(
      id: 'tempo-diagnostic-test',
      listId: 'diagnostics',
      title: 'Tempo 两分钟定时提醒测试',
      dueDate: now.add(delay),
      createdAt: now,
      updatedAt: now,
    );
    return scheduleTaskReminder(task);
  }

  Future<void> cancelAll() {
    return _serialize(() async {
      if (!_initialized) await init();
      await _plugin.cancelAll();
    });
  }

  Future<ReminderScheduleResult> _scheduleSingle(
    Task task,
    DateTime? due,
    String payloadTaskId, {
    DateTime? occurrenceDate,
    String? body,
  }) async {
    if (due == null || task.isCompleted) {
      return _recordResult(
        ReminderScheduleResult(
          status: ReminderScheduleStatus.skippedCompleted,
          taskId: payloadTaskId,
        ),
      );
    }
    final reminderAt = todoReminderDateTime(task, due);
    if (!reminderAt.isAfter(_now())) {
      return _recordResult(
        ReminderScheduleResult(
          status: ReminderScheduleStatus.skippedPast,
          taskId: payloadTaskId,
          scheduledAt: reminderAt,
        ),
      );
    }
    final id = occurrenceDate != null
        ? _occurrenceNotificationId(payloadTaskId, occurrenceDate)
        : _notificationId(payloadTaskId);
    try {
      final capability = await this.capability();
      if (!capability.notificationsAllowed) {
        return _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.notificationsDenied,
            taskId: payloadTaskId,
            notificationId: id,
            scheduledAt: reminderAt,
          ),
        );
      }
      if (!capability.channelEnabled) {
        return _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.channelDisabled,
            taskId: payloadTaskId,
            notificationId: id,
            scheduledAt: reminderAt,
          ),
        );
      }
      final scheduleMode = androidScheduleModeForCapability(
        capability.exactAlarmsAllowed,
      );
      await _zonedSchedule(
        id: id,
        title: '待办提醒',
        body: body ?? task.title,
        scheduledTime: reminderAt,
        payload: _notificationPayload(payloadTaskId, occurrenceDate),
        androidScheduleMode: scheduleMode,
      );
      final pending = await _plugin.pendingNotificationRequests();
      if (!pending.any((request) => request.id == id)) {
        return _recordResult(
          ReminderScheduleResult(
            status: ReminderScheduleStatus.pendingVerificationFailed,
            taskId: payloadTaskId,
            notificationId: id,
            scheduledAt: reminderAt,
            error: '排程后未在系统 pending 列表中找到通知',
          ),
        );
      }
      return _recordResult(
        ReminderScheduleResult(
          status: capability.exactAlarmsAllowed
              ? ReminderScheduleStatus.scheduled
              : ReminderScheduleStatus.scheduledInexact,
          taskId: payloadTaskId,
          notificationId: id,
          scheduledAt: reminderAt,
        ),
      );
    } catch (error) {
      return _recordResult(
        ReminderScheduleResult(
          status: ReminderScheduleStatus.platformFailure,
          taskId: payloadTaskId,
          notificationId: id,
          scheduledAt: reminderAt,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: reminderAtToZonedDateTime(scheduledTime),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher_monochrome',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: androidScheduleMode,
      title: title,
      body: body,
      payload: payload,
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
    );
    await _androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('[Tempo] cancel($id) ignored: $error');
    }
  }

  Future<bool> _cancelPendingWhere(
    bool Function(PendingNotificationRequest request) matches,
  ) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (matches(request)) await _safeCancel(request.id);
      }
      return true;
    } catch (error) {
      debugPrint('[Tempo] pendingNotificationRequests ignored: $error');
      return false;
    }
  }

  Future<T> _serializeResult<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final completer = Completer<void>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final taskId = taskIdFromNotificationPayload(response.payload);
    if (taskId != null && taskId.isNotEmpty) onNotificationTap?.call(taskId);
  }

  int _notificationId(String taskId) =>
      stableNotificationIdForKey('task:$taskId');

  int _occurrenceNotificationId(String taskId, DateTime occurrenceDate) =>
      stableNotificationIdForKey(
        'task:$taskId:occurrence:${_formatCalendarDay(occurrenceDate)}',
      );

  String _notificationPayload(String taskId, DateTime? occurrenceDate) =>
      jsonEncode({
        'v': 1,
        'taskId': taskId,
        if (occurrenceDate != null)
          'occurrenceDate': _formatCalendarDay(occurrenceDate),
      });

  String? _occurrenceDateFromNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['occurrenceDate'];
        return value is String ? value : null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _formatCalendarDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
