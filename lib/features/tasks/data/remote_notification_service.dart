// ============================================================
// RemoteNotificationService — FCM 设备注册与远端通知点击处理
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

typedef ForegroundReminderHandler =
    Future<void> Function({
      required String reminderKey,
      required String taskId,
      required String title,
      required String body,
      String? occurrenceDate,
      String? reminderAt,
    });

class RemoteNotificationService {
  RemoteNotificationService({
    required SupabaseClient supabase,
    FirebaseMessaging? messaging,
    ForegroundReminderHandler? showForegroundReminder,
    Stream<RemoteMessage>? foregroundMessages,
    Stream<RemoteMessage>? openedMessages,
    Future<bool> Function()? ensureFirebaseInitialized,
    void Function(bool registered)? onRegistrationChanged,
  }) : _supabase = supabase,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _showForegroundReminder = showForegroundReminder,
       _foregroundMessages = foregroundMessages ?? FirebaseMessaging.onMessage,
       _openedMessages = openedMessages ?? FirebaseMessaging.onMessageOpenedApp,
       _ensureFirebase = ensureFirebaseInitialized,
       _onRegistrationChanged = onRegistrationChanged;

  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging;
  final ForegroundReminderHandler? _showForegroundReminder;
  final Stream<RemoteMessage> _foregroundMessages;
  final Stream<RemoteMessage> _openedMessages;
  final Future<bool> Function()? _ensureFirebase;
  final void Function(bool registered)? _onRegistrationChanged;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;
  bool _firebaseAvailable = false;
  bool _lastEnabled = true;

  void Function(String taskId)? onNotificationTap;

  Future<void> init({void Function(String taskId)? onNotificationTap}) async {
    if (onNotificationTap != null) {
      this.onNotificationTap = onNotificationTap;
    }
    if (_initialized) return;

    _firebaseAvailable =
        await (_ensureFirebase?.call() ?? _ensureFirebaseInitialized());
    if (!_firebaseAvailable) {
      _initialized = true;
      return;
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    _openedSubscription = _openedMessages.listen(_handleMessageTap);
    _foregroundSubscription = _foregroundMessages.listen(
      _handleForegroundMessage,
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      scheduleMicrotask(() => _handleMessageTap(initialMessage));
    }
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_syncRefreshedToken(token));
    });

    _initialized = true;
  }

  Future<bool> syncDevice({required bool enabled}) async {
    _lastEnabled = enabled;
    if (!_initialized) await init();
    if (!_firebaseAvailable) {
      _onRegistrationChanged?.call(false);
      return false;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _onRegistrationChanged?.call(false);
        return false;
      }
      final synced = await _upsertToken(token: token, enabled: enabled);
      final registered = enabled && synced;
      _onRegistrationChanged?.call(registered);
      return registered;
    } catch (e) {
      _debugRegistrationFailure('get FCM token failed', e);
      _onRegistrationChanged?.call(false);
      return false;
    }
  }

  Future<bool> setRemindersEnabled(bool enabled) {
    return syncDevice(enabled: enabled);
  }

  Future<void> disableCurrentDevice() async {
    _lastEnabled = false;
    if (!_initialized) await init();
    if (_firebaseAvailable) {
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _upsertToken(token: token, enabled: false);
        }
      } catch (e) {
        _debugRegistrationFailure('disable FCM token failed', e);
      }
    }
    _onRegistrationChanged?.call(false);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }

  Future<bool> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      assert(() {
        debugPrint(
          '[Tempo] Firebase unavailable, remote reminders disabled: $e',
        );
        return true;
      }());
      return false;
    }
  }

  Future<bool> _upsertToken({
    required String token,
    required bool enabled,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      await _supabase.from(AppConstants.tableNotificationDevices).upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': _platformName,
        'timezone': timezone.identifier,
        'enabled': enabled,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');
      return true;
    } catch (e) {
      _debugRegistrationFailure('sync remote notification token failed', e);
      return false;
    }
  }

  Future<void> _syncRefreshedToken(String token) async {
    final synced = await _upsertToken(token: token, enabled: _lastEnabled);
    _onRegistrationChanged?.call(_lastEnabled && synced);
  }

  void _debugRegistrationFailure(String operation, Object error) {
    assert(() {
      debugPrint('[Tempo] $operation: $error');
      return true;
    }());
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final handler = _showForegroundReminder;
    if (handler == null) return;
    final taskId = message.data['taskId'];
    final reminderKey = message.data['reminderKey'];
    if (taskId is! String ||
        taskId.isEmpty ||
        reminderKey is! String ||
        reminderKey.isEmpty) {
      return;
    }
    await handler(
      reminderKey: reminderKey,
      taskId: taskId,
      title: message.notification?.title ?? '待办提醒',
      body: message.notification?.body ?? '',
      occurrenceDate: _stringData(message, 'occurrenceDate'),
      reminderAt: _stringData(message, 'reminderAt'),
    );
  }

  String? _stringData(RemoteMessage message, String key) {
    final value = message.data[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  void _handleMessageTap(RemoteMessage message) {
    final taskId = message.data['taskId'];
    if (taskId is String && taskId.isNotEmpty) {
      onNotificationTap?.call(taskId);
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
