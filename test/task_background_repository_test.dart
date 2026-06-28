import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/database/database.dart';
import 'package:tempo/features/tasks/data/task_background_repository.dart';

void main() {
  test('set, replace, and clear task background files', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final dir = Directory.systemTemp.createTempSync('tempo_task_bg_repo_');
    addTearDown(() async {
      await db.close();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

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
          TasksCompanion.insert(id: 'task-1', listId: 'list-1', title: 'Task'),
        );

    final sourceA = File('${dir.path}/source-a.jpg')
      ..writeAsStringSync('first');
    final sourceB = File('${dir.path}/source-b.jpg')
      ..writeAsStringSync('second');
    final repository = LocalTaskBackgroundRepository(
      db: db,
      documentsDirectory: () async => dir,
    );

    final first = await repository.setBackgroundFromFile(
      taskId: 'task-1',
      sourcePath: sourceA.path,
    );
    expect(File(first.imagePath).existsSync(), isTrue);

    final second = await repository.setBackgroundFromFile(
      taskId: 'task-1',
      sourcePath: sourceB.path,
    );
    expect(second.imagePath, isNot(first.imagePath));
    expect(File(first.imagePath).existsSync(), isFalse);
    expect(File(second.imagePath).existsSync(), isTrue);

    final saved = await repository.getBackground('task-1');
    expect(saved?.imagePath, second.imagePath);

    await repository.clearBackground('task-1');
    expect(await repository.getBackground('task-1'), isNull);
    expect(File(second.imagePath).existsSync(), isFalse);
  });
}
