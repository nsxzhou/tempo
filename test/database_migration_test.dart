import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:tempo/database/database.dart';

void main() {
  test('migrates from schema v6 to v7 and adds recurrence tables', () async {
    final file = File(
      '${Directory.systemTemp.path}/tempo_v5_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    _createV5Schema(file.path);

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final versionRow = await db
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(versionRow.read<int>('user_version'), 7);

    await db
        .into(db.taskLists)
        .insert(
          TaskListsCompanion.insert(
            id: 'list-1',
            userId: 'user-1',
            name: 'Inbox',
          ),
        );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-1',
            listId: 'list-1',
            title: 'Task',
            recurrenceRule: const Value('FREQ=DAILY;INTERVAL=1'),
          ),
        );

    await db
        .into(db.taskCompletions)
        .insert(
          TaskCompletionsCompanion.insert(
            taskId: 'task-1',
            occurrenceDate: DateTime(2026, 6, 1),
          ),
        );

    final completion = await (db.select(
      db.taskCompletions,
    )..where((row) => row.taskId.equals('task-1'))).getSingleOrNull();
    expect(completion, isNotNull);

    final dir = Directory.systemTemp.createTempSync('tempo_bg_migrate_');
    final imagePath = File('${dir.path}/bg.jpg')..writeAsStringSync('bg');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    await db
        .into(db.taskBackgrounds)
        .insert(
          TaskBackgroundsCompanion.insert(
            taskId: 'task-1',
            imagePath: imagePath.path,
          ),
        );

    final saved = await (db.select(
      db.taskBackgrounds,
    )..where((row) => row.taskId.equals('task-1'))).getSingleOrNull();
    expect(saved?.imagePath, imagePath.path);
  });
}

void _createV5Schema(String path) {
  final db = sqlite3.open(path);
  try {
    db.execute('''
      CREATE TABLE task_lists (
        id TEXT NOT NULL PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
        sync_pending INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE tasks (
        id TEXT NOT NULL PRIMARY KEY,
        list_id TEXT NOT NULL REFERENCES task_lists(id),
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        siyuan_block_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
        creation_source TEXT NOT NULL DEFAULT 'text',
        tag TEXT,
        sync_pending INTEGER NOT NULL DEFAULT 0
      );

      CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks (due_date);
      CREATE INDEX IF NOT EXISTS idx_tasks_is_completed ON tasks (is_completed);
      CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks (completed_at);
      CREATE INDEX IF NOT EXISTS idx_tasks_list_id ON tasks (list_id);

      CREATE TABLE task_backgrounds (
        task_id TEXT NOT NULL PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
      );
    ''');
    db.execute('PRAGMA user_version = 6');
  } finally {
    db.dispose();
  }
}
