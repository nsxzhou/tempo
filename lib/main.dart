// ============================================================
// Tempo App 入口
// 初始化 Supabase + 通知 + timezone
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 加载 .env(必须在 Supabase.initialize 之前;AppConstants getter 读 dotenv)
  await dotenv.load(fileName: '.env');

  // 2) 初始化 Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: true, // DEBUG: 开启 HTTP 请求/响应日志
    // supabase_flutter 自动处理 custom scheme deep link
    // redirect URL 在 Auth 配置中设置为 tempo://login-callback
  );

  // DEBUG: 打印当前生效的 supabase 配置(确认是云端不是 127.0.0.1)
  // ignore: avoid_print
  print('[TEMPO-DEBUG] supabaseUrl = ${AppConstants.supabaseUrl}');
  // ignore: avoid_print
  print('[TEMPO-DEBUG] anonKey prefix = ${AppConstants.supabaseAnonKey.substring(0, 12)}...');
  // ignore: avoid_print
  print('[TEMPO-DEBUG] parseTaskEndpoint = ${AppConstants.parseTaskEndpoint}');

  // 3) 初始化 timezone 数据（本地通知 zonedSchedule 需要）
  tz.initializeTimeZones();

  // 4) 初始化 intl locale 数据(tasks_page / calendar_page 用了 zh_CN 的 DateFormat)
  await initializeDateFormatting('zh_CN');

  runApp(const ProviderScope(child: TempoApp()));
}
