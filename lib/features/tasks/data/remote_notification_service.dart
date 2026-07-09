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

class RemoteNotificationService {
  RemoteNotificationService({
    required SupabaseClient supabase,
    FirebaseMessaging? messaging,
  }) : _supabase = supabase,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;
  bool _firebaseAvailable = false;
  bool _lastEnabled = true;

  void Function(String taskId)? onNotificationTap;

  Future<void> init({void Function(String taskId)? onNotificationTap}) async {
    if (onNotificationTap != null) {
      this.onNotificationTap = onNotificationTap;
    }
    if (_initialized) return;

    _firebaseAvailable = await _ensureFirebaseInitialized();
    if (!_firebaseAvailable) {
      _initialized = true;
      return;
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageTap,
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      scheduleMicrotask(() => _handleMessageTap(initialMessage));
    }
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_upsertToken(token: token, enabled: _lastEnabled));
    });

    _initialized = true;
  }

  Future<void> syncDevice({required bool enabled}) async {
    _lastEnabled = enabled;
    if (!_initialized) await init();
    if (!_firebaseAvailable) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _upsertToken(token: token, enabled: enabled);
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    await syncDevice(enabled: enabled);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _openedSubscription?.cancel();
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

  Future<void> _upsertToken({
    required String token,
    required bool enabled,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

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
    } catch (e) {
      assert(() {
        debugPrint('[Tempo] sync remote notification token failed: $e');
        return true;
      }());
    }
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
