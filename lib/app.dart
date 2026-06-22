// ============================================================
// TempoApp — 应用根 Widget
// ConsumerStatefulWidget + GoRouter Provider
// 集成: Auth 状态驱动路由刷新 + 通知初始化(tap→详情页)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_state_widget.dart';

/// Tempo 应用入口 Widget
class TempoApp extends ConsumerStatefulWidget {
  const TempoApp({super.key});

  @override
  ConsumerState<TempoApp> createState() => _TempoAppState();
}

class _TempoAppState extends ConsumerState<TempoApp> {
  @override
  void initState() {
    super.initState();

    // ── 通知初始化 + tap 回调 ──
    // 同步设置 onNotificationTap，确保冷启动从通知唤起时也能跳转
    final notificationService = ref.read(notificationServiceProvider);
    final router = ref.read(routerProvider);
    notificationService.onNotificationTap = (taskId) {
      router.go('/tasks/$taskId');
    };

    // 异步初始化通知插件（插件 initialize + Android channel 创建）
    notificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return AuthStateWidget(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // 浅色背景 → 状态栏图标用深色(电池/信号/时间黑/灰)
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppTheme.bg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MaterialApp.router(
          title: 'Tempo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light, // Phase 2 支持 dark
          routerConfig: router,
        ),
      ),
    );
  }
}
