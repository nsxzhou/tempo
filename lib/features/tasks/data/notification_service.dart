// ============================================================
// NotificationService — 本地待办提醒调度
// 创建/更新任务时调度提醒；完成/删除时取消通知
// 通知 ID 映射: taskId.hashCode
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../domain/task.dart';

/// 计算待办提醒的本地时刻（dueDate 日历日 08:00）。
DateTime todoReminderDateTime(DateTime dueDate) {
  return DateTime(dueDate.year, dueDate.month, dueDate.day, 8);
}

/// 本地通知服务。
///
/// 使用 flutter_local_notifications 为有日期的待办调度提醒。
/// 每个任务 1 条通知：对应日历日当天 08:00。
///
/// 通知 ID 映射：taskId.hashCode
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  static SharedPreferences? _prefsCache;

  static Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  /// 通知点击回调（由 App 设置，用于导航到详情页）。
  void Function(String taskId)? onNotificationTap;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// 初始化通知插件和 timezone。
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

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
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createAndroidChannel();

    _initialized = true;
  }

  /// 请求通知权限（iOS 需要显式请求，Android 13+ 也需要）。
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

  /// 读取用户是否开启待办提醒。
  Future<bool> isRemindersEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(AppConstants.prefNotificationEnabled) ?? true;
  }

  /// 更新提醒开关；关闭时取消全部已调度通知。
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

  /// 为所有符合条件的任务重新调度提醒（开启开关后调用）。
  Future<void> rescheduleAllTasks(Iterable<Task> tasks) async {
    if (!await isRemindersEnabled()) return;
    const batchSize = 10;
    final list = tasks.toList();
    for (var i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      for (var j = i; j < end; j++) {
        unawaited(scheduleTaskReminder(list[j]));
      }
      if (end < list.length) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  /// 为任务调度待办提醒（对应日历日 08:00）。
  ///
  /// 仅当 task.dueDate != null && !isCompleted && 提醒时刻 > now 时调度。
  /// 通知调度为 best-effort：失败时不抛出，避免任务已创建却报失败。
  Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (!_initialized) await init();

      if (!await isRemindersEnabled()) return;

      await cancelTaskReminders(task.id);

      if (task.dueDate == null || task.isCompleted) return;

      final now = DateTime.now();
      final reminderAt = todoReminderDateTime(task.dueDate!);

      if (!reminderAt.isAfter(now)) return;

      await _zonedSchedule(
        id: _notificationId(task.id),
        title: '待办提醒',
        body: task.title,
        scheduledTime: reminderAt,
        payload: task.id,
      );
    } catch (e, stack) {
      _debugPrintNotificationFailure(
        'scheduleTaskReminder failed for ${task.id}',
        e,
        stack,
      );
    }
  }

  /// 取消任务的待办提醒。
  Future<void> cancelTaskReminders(String taskId) async {
    await _plugin.cancel(_notificationId(taskId));
    // 兼容旧版双通知 ID，避免升级后残留到期提醒。
    await _plugin.cancel(_notificationId(taskId) + 1);
  }

  /// 取消所有通知。
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
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

  // ── 内部方法 ──

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
    final tzTime = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);
    final androidScheduleMode = await _androidScheduleMode();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  int _notificationId(String taskId) => taskId.hashCode;
}
