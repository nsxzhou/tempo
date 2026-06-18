// ============================================================
// Tempo App 入口
// 初始化 Supabase + 通知 + timezone
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // supabase_flutter 自动处理 custom scheme deep link
    // redirect URL 在 Auth 配置中设置为 tempo://login-callback
  );

  // 3) 初始化 timezone 数据（本地通知 zonedSchedule 需要）
  tz.initializeTimeZones();

  runApp(const ProviderScope(child: TempoApp()));
}
