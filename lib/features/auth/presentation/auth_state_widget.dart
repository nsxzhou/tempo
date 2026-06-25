// ============================================================
// AuthStateWidget — Auth 状态监听 Widget
// 监听 Supabase auth 状态变化，驱动路由跳转 + 启动同步服务
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';

/// Auth 状态监听 Widget。
///
/// 监听 [authStateProvider] 变化：
/// 1. 在 auth 状态切换时通过 GoRouter 的 refresh() 触发路由守卫重新评估
/// 2. 用户登录后启动 SyncService 监听网络恢复并推送 pending
class AuthStateWidget extends ConsumerStatefulWidget {
  final Widget child;

  const AuthStateWidget({super.key, required this.child});

  @override
  ConsumerState<AuthStateWidget> createState() => _AuthStateWidgetState();
}

class _AuthStateWidgetState extends ConsumerState<AuthStateWidget> {
  bool _syncStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authStateProvider).valueOrNull;
      if (session != null) {
        _tryStartSync();
        unawaited(ref.read(siyuanBindingStatusProvider.future));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      final wasLoggedOut = previous?.valueOrNull == null;
      final isLoggedIn = next.valueOrNull != null;
      if (wasLoggedOut && isLoggedIn) {
        _tryStartSync();
        unawaited(ref.read(siyuanBindingStatusProvider.future));
      }
      if (!isLoggedIn && previous?.valueOrNull != null) {
        _syncStarted = false;
      }
    });

    return widget.child;
  }

  void _tryStartSync() {
    if (_syncStarted) return;
    _syncStarted = true;
    try {
      ref.read(syncServiceProvider).startListening();
    } catch (_) {
      _syncStarted = false;
    }
  }
}
