// ============================================================
// FeedbackService — 提交反馈到 Supabase feedback 表
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// 反馈领域模型。
class Feedback {
  final String id;
  final String userId;
  final String content;
  final Map<String, dynamic>? deviceInfo;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.content,
    this.deviceInfo,
    required this.createdAt,
  });
}

/// 反馈服务：提交用户反馈到 Supabase feedback 表。
class FeedbackService {
  final SupabaseClient _supabase;
  final String? _userId;

  FeedbackService({
    required SupabaseClient supabase,
    required String? userId,
  })  : _supabase = supabase,
        _userId = userId;

  /// 提交反馈。
  ///
  /// [content] 反馈内容文字。
  /// [deviceInfo] 设备信息（平台/版本/型号等），自动附带。
  Future<void> submit(
    String content, {
    Map<String, dynamic>? deviceInfo,
  }) async {
    if (_userId == null) {
      throw StateError('用户未登录，无法提交反馈');
    }

    if (content.trim().isEmpty) {
      throw ArgumentError('反馈内容不能为空');
    }

    await _supabase.from(AppConstants.tableFeedback).insert({
      'user_id': _userId,
      'content': content.trim(),
      'device_info': deviceInfo,
    });
  }
}
