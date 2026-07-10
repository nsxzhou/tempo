import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo/features/tasks/data/remote_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foreground FCM is converted to one system reminder', () async {
    final foreground = StreamController<RemoteMessage>();
    final opened = StreamController<RemoteMessage>();
    final handled = <Map<String, String?>>[];
    final service = RemoteNotificationService(
      supabase: SupabaseClient(
        'https://example.supabase.co',
        'test-publishable-key',
      ),
      messaging: _FakeFirebaseMessaging(),
      foregroundMessages: foreground.stream,
      openedMessages: opened.stream,
      ensureFirebaseInitialized: () async => true,
      showForegroundReminder:
          ({
            required reminderKey,
            required taskId,
            required title,
            required body,
            occurrenceDate,
            reminderAt,
          }) async {
            handled.add({
              'reminderKey': reminderKey,
              'taskId': taskId,
              'title': title,
              'body': body,
              'occurrenceDate': occurrenceDate,
              'reminderAt': reminderAt,
            });
          },
    );

    await service.init();
    foreground.add(
      RemoteMessage.fromMap({
        'data': {
          'reminderKey': 'task-1:2026-07-10:at',
          'taskId': 'task-1',
          'occurrenceDate': '2026-07-10',
          'reminderAt': '2026-07-10T01:00:00.000Z',
        },
        'notification': {'title': '待办提醒', 'body': '死虫式'},
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, hasLength(1));
    expect(handled.single['taskId'], 'task-1');
    expect(handled.single['occurrenceDate'], '2026-07-10');

    await service.dispose();
    await foreground.close();
    await opened.close();
  });
}

class _FakeFirebaseMessaging implements FirebaseMessaging {
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    return const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
