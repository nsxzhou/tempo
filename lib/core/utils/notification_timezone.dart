import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

bool _configured = false;

/// 配置本地时区，供 [NotificationService] 的 zonedSchedule 使用。
Future<void> configureNotificationTimezone() async {
  if (_configured) return;
  tz.initializeTimeZones();
  if (kIsWeb) {
    _configured = true;
    return;
  }
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  }
  _configured = true;
}

@visibleForTesting
void configureNotificationTimezoneForTest([
  String locationName = 'Asia/Shanghai',
]) {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(locationName));
  _configured = true;
}

@visibleForTesting
void resetNotificationTimezoneForTest() {
  _configured = false;
}

tz.TZDateTime reminderAtToZonedDateTime(DateTime reminderAt) {
  return tz.TZDateTime(
    tz.local,
    reminderAt.year,
    reminderAt.month,
    reminderAt.day,
    reminderAt.hour,
    reminderAt.minute,
    reminderAt.second,
    reminderAt.millisecond,
    reminderAt.microsecond,
  );
}
