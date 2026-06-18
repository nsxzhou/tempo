// ============================================================
// AuthService — Magic Link 登录 + session 管理 + 登出
// 使用 supabase_flutter 的 Auth API 实现 Magic Link 登录流程。
// ============================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Auth 服务：封装 Supabase Auth 操作。
///
/// 提供 Magic Link 登录、登出、session 状态监听。
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// 发送 Magic Link 登录邮件。
  ///
  /// 邮件中的链接会以 `tempo://login-callback` scheme 唤起 App，
  /// supabase_flutter 自动处理 session 交换。
  Future<void> sendMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: AppConstants.deepLinkCallback,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('=== [AUTH-ERROR] $e');
      // ignore: avoid_print
      print('=== [AUTH-STACK] $st');
      rethrow;
    }
  }

  /// 登出，清除当前 session。
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 当前登录用户（可能为 null）。
  User? get currentUser => _client.auth.currentUser;

  /// 当前 session（可能为 null）。
  Session? get currentSession => _client.auth.currentSession;

  /// Auth 状态流，发射 Session? 变化。
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// 当前用户 ID（便捷访问）。
  String? get currentUserId => currentUser?.id;

  /// 当前用户邮箱（便捷访问）。
  String? get currentUserEmail => currentUser?.email;
}

/// Supabase 客户端 Provider（全局单例）。
///
/// 在 main.dart 中通过 Supabase.initialize 初始化后，
/// 通过 Supabase.instance.client 获取全局单例。
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// AuthService Provider。
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthService(client);
});

/// Auth 状态 Provider：监听 Supabase auth 状态变化，发射当前 Session?。
///
/// 使用 StreamProvider 确保路由守卫能响应式地刷新。
final authStateProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseProvider);
  // 先发射当前 session（App 启动时恢复），再监听后续变化
  final controller = StreamController<Session?>();
  controller.add(client.auth.currentSession);

  final subscription = client.auth.onAuthStateChange.listen((event) {
    controller.add(event.session);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// 当前用户 ID Provider（便捷访问，其他 provider 依赖此值）。
final currentUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authStateProvider).valueOrNull;
  return session?.user.id;
});

/// 当前用户邮箱 Provider。
final currentUserEmailProvider = Provider<String?>((ref) {
  final session = ref.watch(authStateProvider).valueOrNull;
  return session?.user.email;
});
