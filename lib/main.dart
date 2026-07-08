// ============================================================
// Tempo App 入口
// 初始化 Supabase + 通知 + timezone
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/notification_timezone.dart';
import 'core/providers/rebuild_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 加载 .env(必须在 Supabase.initialize 之前;AppConstants getter 读 dotenv)
  await dotenv.load(fileName: '.env');

  // 2) 初始化 Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
    debug: false,
    // supabase_flutter 自动处理 custom scheme deep link
    // redirect URL 在 Auth 配置中设置为 tempo://login-callback
  );

  // 3) 初始化本地时区（本地通知 zonedSchedule 需要）
  await configureNotificationTimezone();

  // 4) 初始化 intl locale 数据(tasks_page / calendar_page 用了 zh_CN 的 DateFormat)
  await initializeDateFormatting('zh_CN');

  runApp(
    ProviderScope(
      observers: kDebugMode
          ? [
              RebuildObserver(const {
                'taskListProvider',
                'calendarTaskIndexProvider',
              }),
            ]
          : const [],
      child: const TempoApp(),
    ),
  );
}
