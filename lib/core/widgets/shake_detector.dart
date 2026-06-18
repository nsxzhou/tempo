// ============================================================
// ShakeDetector — 摇一摇检测
// 使用加速度传感器检测设备摇动，触发反馈入口
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 摇一摇手势检测器。
///
/// 监听加速度传感器，当检测到设备摇动幅度超过阈值时触发回调。
/// 使用防抖逻辑避免短时间内重复触发。
class ShakeDetector {
  static const double _shakeThresholdGravity = 2.7;
  static const int _shakeSlopTimeMs = 500;
  static const int _shakeCountResetTimeMs = 3000;

  final VoidCallback onShake;
  StreamSubscription<AccelerometerEvent>? _subscription;
  int _shakeCount = 0;
  int _lastShakeTimestamp = 0;

  ShakeDetector({required this.onShake});

  /// 开始监听加速度传感器。
  void startListening() {
    _subscription?.cancel();
    _subscription = accelerometerEventStream().listen(_onAccelerometerEvent);
  }

  /// 停止监听。
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 计算加速度的 g 值（减去重力 9.8）
    final gX = event.x / 9.8;
    final gY = event.y / 9.8;
    final gZ = event.z / 9.8;

    // 计算总加速度幅度
    final gForce = (gX * gX + gY * gY + gZ * gZ).abs();

    if (gForce > _shakeThresholdGravity) {
      // 防抖：距离上次摇动太近则忽略
      if (now - _lastShakeTimestamp < _shakeSlopTimeMs) {
        return;
      }

      // 重置计数器：超过 3 秒没摇动则归零
      if (now - _lastShakeTimestamp > _shakeCountResetTimeMs) {
        _shakeCount = 0;
      }

      _shakeCount++;
      _lastShakeTimestamp = now;

      // 至少 1 次摇动即触发（更灵敏）
      if (_shakeCount >= 1) {
        onShake();
        _shakeCount = 0;
      }
    }
  }

  /// 释放资源。
  void dispose() {
    stopListening();
  }
}
