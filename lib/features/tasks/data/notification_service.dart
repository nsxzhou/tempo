// ============================================================
// NotificationService — 本地通知调度
// 创建/更新任务时调度提醒通知；完成/删除时取消通知
// 通知 ID 映射: taskId.hashCode = reminder, taskId.hashCode + 1 = due
// ============================================================

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../domain/task.dart';

/// 本地通知服务。
///
/// 使用 flutter_local_notifications 调度任务提醒通知。
/// 每个任务最多 2 条通知：
/// - reminder: 到期前 15 分钟
/// - due: 到期时
///
/// 通知 ID 映射：
/// - reminder ID = taskId.hashCode
/// - due ID = taskId.hashCode + 1
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// 通知点击回调（由 App 设置，用于导航到详情页）。
  void Function(String taskId)? onNotificationTap;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// 初始化通知插件和 timezone。
  Future<void> init() async {
    if (_initialized) return;

    // 初始化 timezone 数据
    tz.initializeTimeZones();

    // Android 设置
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS 设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 创建 Android 通知 channel
    await _createAndroidChannel();

    _initialized = true;
  }

  /// 请求通知权限（iOS 需要显式请求，Android 13+ 也需要）。
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    // iOS
    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android 13+
    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iosResult ?? androidResult ?? true;
  }

  /// 为任务调度提醒通知（到期前 15 分钟 + 到期时）。
  ///
  /// 仅当 task.dueDate != null && !isCompleted && dueDate > now 时调度。
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) await init();

    // 取消已有通知（重新调度时先清理）
    await cancelTaskReminders(task.id);

    if (task.dueDate == null || task.isCompleted) return;

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    // 到期时间已过，不调度
    if (dueDate.isBefore(now)) return;

    final reminderTime = dueDate.subtract(
      Duration(minutes: AppConstants.reminderBeforeMinutes),
    );

    // 调度 reminder 通知（到期前 15 分钟）
    if (reminderTime.isAfter(now)) {
      await _zonedSchedule(
        id: _reminderNotificationId(task.id),
        title: '任务即将到期',
        body: task.title,
        scheduledTime: reminderTime,
        payload: task.id,
      );
    }

    // 调度 due 通知（到期时）
    await _zonedSchedule(
      id: _dueNotificationId(task.id),
      title: '任务已到期',
      body: task.title,
      scheduledTime: dueDate,
      payload: task.id,
    );
  }

  /// 取消任务的所有通知。
  Future<void> cancelTaskReminders(String taskId) async {
    await _plugin.cancel(_reminderNotificationId(taskId));
    await _plugin.cancel(_dueNotificationId(taskId));
  }

  /// 取消所有通知。
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  /// 通知 ID 映射：reminder = taskId.hashCode
  int _reminderNotificationId(String taskId) => taskId.hashCode;

  /// 通知 ID 映射：due = taskId.hashCode + 1
  int _dueNotificationId(String taskId) => taskId.hashCode + 1;
}
