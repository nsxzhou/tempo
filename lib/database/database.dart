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

  /// 测试用构造函数（可注入自定义 executor）。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2: 新增 syncPending 字段到 Tasks 和 TaskLists 表
        if (from < 2) {
          await m.addColumn(tasks, tasks.syncPending);
          await m.addColumn(taskLists, taskLists.syncPending);
        }
        if (from < 3) {
          await m.addColumn(tasks, tasks.tag);
        }
        if (from < 4) {
          await m.addColumn(tasks, tasks.isAllDay);
        }
      },
    );
  }

  // ── 便捷查询方法 ──

  /// 获取所有任务
  Future<List<Map<String, dynamic>>> allTasks() async {
    final rows = await select(tasks).get();
    return rows.map((r) => r.toJson()).toList();
  }

  /// 按 ID 获取任务列表（详情页归属名称用）。
  Future<TaskList?> getTaskListById(String id) =>
      (select(taskLists)..where((l) => l.id.equals(id))).getSingleOrNull();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tempo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
