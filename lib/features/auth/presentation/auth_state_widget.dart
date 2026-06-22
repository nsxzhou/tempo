// ============================================================
// AuthStateWidget — Auth 状态监听 Widget
// 监听 Supabase auth 状态变化，驱动路由跳转 + 启动同步服务
// ============================================================

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
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).valueOrNull;

    // 登录后立即预取思源绑定状态，进入「我的」前数据已就绪。
    if (session != null) {
      ref.watch(siyuanBindingStatusProvider);
    }

    // 当用户登录时，启动 SyncService
    // 使用 listen 避免在 build 中直接执行副作用
    ref.listen(authStateProvider, (previous, next) {
      final newSession = next.valueOrNull;
      if (newSession != null && (previous?.valueOrNull == null)) {
        // 从未登录变为已登录，启动同步
        _startSyncService();
      }
    });

    // 如果当前已登录（App 启动时恢复 session），也启动同步
    if (session != null) {
      // 使用 microtask 避免在 build 中直接修改 provider 状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSyncService();
      });
    }

    return widget.child;
  }

  void _startSyncService() {
    try {
      // 读取 SyncService 并启动监听
      // 注意：syncServiceProvider 依赖 taskRepositoryProvider，后者依赖 currentUserIdProvider
      // 只有当 userId 可用时，SyncService 才能正常工作
      ref.read(syncServiceProvider).startListening();
    } catch (_) {
      // 静默忽略：如果 provider 尚未就绪，下次 auth 状态变化时会重试
    }
  }
}
