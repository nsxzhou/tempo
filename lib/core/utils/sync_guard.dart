/// 同步守卫：封装网络状态 + 用户身份的前置检查。
library;

import '../../features/tasks/data/task_repository.dart';

/// 同步前置条件检查工具。
///
/// 封装 `isOnline + userId != null` 的重复模式，
/// 提供统一的同步能力判断和条件执行。
class SyncGuard {
  final ConnectivityService _connectivity;
  final String? _userId;

  SyncGuard(this._connectivity, this._userId);

  /// 当前是否满足同步条件（在线 + 已登录）。
  Future<bool> get canSync async {
    final isOnline = await _connectivity.isOnline;
    return isOnline && _userId != null;
  }

  /// 已登录的用户 ID；未登录时为 null。
  String? get userId => _userId;

  /// 若满足同步条件则执行 [action]，否则静默跳过。
  Future<void> executeIfCanSync(Future<void> Function(String userId) action) async {
    final uid = _userId;
    if (uid == null) return;
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) return;
    await action(uid);
  }
}
