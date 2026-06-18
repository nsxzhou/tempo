// ============================================================
// OnboardingManager — SharedPreferences 读写 onboarding_completed
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Onboarding 状态管理器。
///
/// 使用 SharedPreferences 持久化 onboarding 完成状态。
class OnboardingManager {
  /// 检查是否已完成 onboarding。
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;
  }

  /// 标记 onboarding 已完成。
  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingCompleted, true);
  }

  /// 重置 onboarding 状态（用于测试或调试）。
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefOnboardingCompleted);
  }
}
