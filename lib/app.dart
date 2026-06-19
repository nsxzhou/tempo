// ============================================================
// TempoApp — 应用根 Widget
// ConsumerStatefulWidget + GoRouter Provider
// 集成: Auth 状态驱动路由刷新 + 通知初始化(tap→详情页) + 摇一摇反馈
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/shake_detector.dart';
import 'features/auth/presentation/auth_state_widget.dart';
import 'features/settings/presentation/feedback_dialog.dart';

/// Tempo 应用入口 Widget
class TempoApp extends ConsumerStatefulWidget {
  const TempoApp({super.key});

  @override
  ConsumerState<TempoApp> createState() => _TempoAppState();
}

class _TempoAppState extends ConsumerState<TempoApp> {
  ShakeDetector? _shakeDetector;
  bool _isShakeActive = false;

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

    // ── 摇一摇初始化 ──
    // 根据当前 auth 状态决定是否启动（仅登录用户启用，避免登录页误触发）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncShakeDetectorWithAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // 监听 auth 状态变化，动态启停摇一摇（仅登录用户启用）
    ref.listen(authStateProvider, (previous, next) {
      final isLoggedIn = next.valueOrNull != null;
      final wasLoggedIn = previous?.valueOrNull != null;
      if (isLoggedIn != wasLoggedIn) {
        _syncShakeDetectorWithAuth();
      }
    });

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

  /// 根据 auth 状态启停摇一摇检测器。
  void _syncShakeDetectorWithAuth() {
    final session = ref.read(authStateProvider).valueOrNull;
    final shouldActivate = session != null;

    if (shouldActivate && !_isShakeActive) {
      _startShakeDetector();
    } else if (!shouldActivate && _isShakeActive) {
      _stopShakeDetector();
    }
  }

  /// 启动摇一摇检测器。
  void _startShakeDetector() {
    _shakeDetector ??= ShakeDetector(
      onShake: () {
        // 使用全局 navigator key 的 context 弹出反馈弹窗
        final navigatorKey = ref.read(appNavigatorKeyProvider);
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          showDialog(
            context: navContext,
            builder: (_) => const FeedbackDialog(),
          );
        }
      },
    );
    _shakeDetector!.startListening();
    _isShakeActive = true;
  }

  /// 停止摇一摇检测器。
  void _stopShakeDetector() {
    _shakeDetector?.stopListening();
    _isShakeActive = false;
  }

  @override
  void dispose() {
    _shakeDetector?.dispose();
    super.dispose();
  }
}
