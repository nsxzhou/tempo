// ============================================================
// SiyuanPairingService — 配对码 + 绑定状态
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

/// 思源绑定与同步状态（来自 siyuan_bindings 表）。
class SiyuanBindingStatus {
  final bool isPaired;
  final DateTime? pairedAt;
  final DateTime? lastSyncAt;
  final int lastImportedCount;
  final String? pluginVersion;
  final PairingCode? pendingCode;

  const SiyuanBindingStatus({
    required this.isPaired,
    this.pairedAt,
    this.lastSyncAt,
    this.lastImportedCount = 0,
    this.pluginVersion,
    this.pendingCode,
  });

  bool get hasSynced => lastSyncAt != null;

  bool get hasPendingCode => pendingCode?.isValid == true;
}

/// 思源配对与绑定服务。
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

  /// 查询当前用户最近一条配对码。
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

      final row = rows[0] as Map<String, dynamic>;
      return _mapPairingCode(row);
    } catch (_) {
      return null;
    }
  }

  /// 读取绑定与同步状态。
  Future<SiyuanBindingStatus> getBindingStatus() async {
    if (_userId == null) {
      return const SiyuanBindingStatus(isPaired: false);
    }

    final pendingCode = await getActiveCode();
    try {
      final row = await _supabase
          .from(AppConstants.tableSiyuanBindings)
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (row == null) {
        return SiyuanBindingStatus(
          isPaired: false,
          pendingCode: pendingCode,
        );
      }

      final map = row;
      return SiyuanBindingStatus(
        isPaired: true,
        pairedAt: map['paired_at'] != null
            ? DateTime.parse(map['paired_at'] as String).toLocal()
            : null,
        lastSyncAt: map['last_sync_at'] != null
            ? DateTime.parse(map['last_sync_at'] as String).toLocal()
            : null,
        lastImportedCount: map['last_sync_imported_count'] as int? ?? 0,
        pluginVersion: map['plugin_version'] as String?,
        pendingCode: pendingCode,
      );
    } catch (_) {
      return SiyuanBindingStatus(
        isPaired: false,
        pendingCode: pendingCode,
      );
    }
  }

  /// App 侧解绑（删除云端绑定记录）。
  Future<void> clearBinding() async {
    if (_userId == null) return;
    await _supabase.rpc('delete_siyuan_binding');
  }

  PairingCode _mapPairingCode(Map<String, dynamic> row) {
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
  }

  String _generateRandomCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }
}
