// ============================================================
// SiyuanPairingService — 生成配对码 + 写入 siyuan_pairing_codes 表
// ============================================================

import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// 配对码领域模型。
class PairingCode {
  final String code;
  final String userId;
  final String userEmail;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;

  PairingCode({
    required this.code,
    required this.userId,
    required this.userEmail,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;
}

/// 思源配对码服务。
///
/// 生成 6 位数字配对码，写入 Supabase siyuan_pairing_codes 表。
/// 配对码 5 分钟有效，一次性使用。
class SiyuanPairingService {
  final SupabaseClient _supabase;
  final String? _userId;
  final String? _userEmail;

  SiyuanPairingService({
    required SupabaseClient supabase,
    required String? userId,
    required String? userEmail,
  })  : _supabase = supabase,
        _userId = userId,
        _userEmail = userEmail;

  /// 生成新的 6 位配对码并写入 Supabase。
  ///
  /// 返回配对码字符串。
  Future<String> generateCode() async {
    if (_userId == null || _userEmail == null) {
      throw StateError('用户未登录，无法生成配对码');
    }

    final code = _generateRandomCode();
    final now = DateTime.now();
    final expiresAt = now.add(AppConstants.pairingCodeExpiry);

    await _supabase.from(AppConstants.tableSiyuanPairingCodes).insert({
      'code': code,
      'user_id': _userId,
      'user_email': _userEmail,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'used_at': null,
    });

    return code;
  }

  /// 查询当前用户是否有有效的配对码。
  Future<PairingCode?> getActiveCode() async {
    if (_userId == null) return null;

    try {
      final rows = await _supabase
          .from(AppConstants.tableSiyuanPairingCodes)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return null;

      final row = rows[0];
      return PairingCode(
        code: row['code'] as String,
        userId: row['user_id'] as String,
        userEmail: row['user_email'] as String,
        expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
        usedAt: row['used_at'] != null
            ? DateTime.parse(row['used_at'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 生成 6 位随机数字配对码（使用 Random.secure）。
  String _generateRandomCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000-999999
    return code.toString();
  }
}
