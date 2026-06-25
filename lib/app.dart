// ============================================================
// TempoApp — 应用根 Widget
// ConsumerStatefulWidget + GoRouter Provider
// 集成: Auth 状态驱动路由刷新 + 通知初始化(tap→详情页)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_manager.dart';
import 'core/widgets/tempo/src/tempo_background.dart';
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

    final notificationService = ref.read(notificationServiceProvider);
    final router = ref.read(routerProvider);
    notificationService.onNotificationTap = (taskId) {
      router.go('/tasks/$taskId');
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapNotifications());
    });
  }

  Future<void> _bootstrapNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.init();
      await notificationService.requestPermissions();
      if (!await notificationService.isRemindersEnabled()) return;

      final tasks = await ref.read(taskRepositoryProvider).watchTasks().first;
      if (tasks.isNotEmpty) {
        unawaited(notificationService.rescheduleAllTasks(tasks));
      }
    } catch (e, stack) {
      assert(() {
        debugPrint('[Tempo] bootstrapNotifications failed: $e');
        debugPrintStack(stackTrace: stack);
        return true;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final tokens = ref.watch(activeTempoTokensProvider);

    return AuthStateWidget(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: tokens.systemUi,
        child: MaterialApp.router(
          title: 'Tempo',
          debugShowCheckedModeBanner: false,
          theme: tokens.toThemeData(),
          routerConfig: router,
          builder: (context, child) {
            return TempoBackground(child: child ?? const SizedBox.shrink());
          },
        ),
      ),
    );
  }
}
