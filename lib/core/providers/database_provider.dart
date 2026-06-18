import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';

/// 数据库 Provider（全局单例）
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
