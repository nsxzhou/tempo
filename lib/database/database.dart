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
  int get schemaVersion => 5;

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
        if (from < 5) {
          await m.createIndex(
            Index(
              'idx_tasks_due_date',
              'CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks (due_date)',
            ),
          );
          await m.createIndex(
            Index(
              'idx_tasks_is_completed',
              'CREATE INDEX IF NOT EXISTS idx_tasks_is_completed ON tasks (is_completed)',
            ),
          );
          await m.createIndex(
            Index(
              'idx_tasks_completed_at',
              'CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks (completed_at)',
            ),
          );
          await m.createIndex(
            Index(
              'idx_tasks_list_id',
              'CREATE INDEX IF NOT EXISTS idx_tasks_list_id ON tasks (list_id)',
            ),
          );
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

  /// 监听指定时间范围内已完成的任务（统计趋势用）。
  Stream<List<Task>> watchCompletedTasksInRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return (select(tasks)
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.completedAt.isNotNull())
          ..where((t) => t.completedAt.isBiggerOrEqualValue(startInclusive))
          ..where((t) => t.completedAt.isSmallerThanValue(endExclusive)))
        .watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tempo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
