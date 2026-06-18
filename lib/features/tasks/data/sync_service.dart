// ============================================================
// SyncService — 同步引擎
// 监听网络状态变化，网络恢复时自动推送 pending 记录
// ============================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_repository.dart';

/// 同步引擎：监听网络状态，自动推送 pending 记录。
///
/// 在 App 启动时调用 [startListening]，网络恢复时自动调用 pushPending()。
class SyncService {
  final TaskRepository _repository;
  final ConnectivityService _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isSyncing = false;

  SyncService({
    required TaskRepository repository,
    required ConnectivityService connectivity,
  })  : _repository = repository,
        _connectivity = connectivity;

  /// 开始监听网络状态，网络恢复时自动推送 pending。
  void startListening() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _onNetworkRestored();
      }
    });

    // 启动时立即推送一次（处理上次离线期间积累的 pending）
    _onNetworkRestored();
  }

  /// 手动触发 pending 推送。
  Future<void> pushPending() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _repository.pushPending();
    } finally {
      _isSyncing = false;
    }
  }

  /// 网络恢复回调：推送 pending 记录。
  void _onNetworkRestored() {
    pushPending();
  }

  /// 停止监听。
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
