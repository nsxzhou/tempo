import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

/// Tempo 本地数据库
///
/// 使用 Drift (SQLite) 作为本地缓存层。
/// 数据以 Supabase 为准，本地数据库提供毫秒级读取体验。
@DriftDatabase(tables: [TaskLists, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本迁移逻辑
      },
    );
  }

  // ── 便捷查询方法 ──

  /// 获取所有任务
  Future<List<Map<String, dynamic>>> allTasks() async {
    final rows = await select(tasks).get();
    return rows.map((r) => r.toJson()).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tempo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
