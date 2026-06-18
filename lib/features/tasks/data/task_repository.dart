import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../database/database.dart' as db;
import '../domain/task.dart' as domain;
import 'voice_task_parse_result.dart';

abstract class TaskRepository {
  Stream<List<domain.Task>> watchTasks();

  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  });

  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result);

  Future<void> deleteTask(String id);
}

class DriftTaskRepository implements TaskRepository {
  static const String defaultListId = 'local-inbox';
  static const String defaultUserId = 'local-user';

  final db.AppDatabase _database;
  final Uuid _uuid;

  DriftTaskRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<domain.Task>> watchTasks() async* {
    await _ensureDefaultList();

    final query = _database.select(_database.tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);

    yield* query.watch().map((rows) => rows.map(_mapTask).toList());
  }

  @override
  Future<domain.Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    domain.TaskPriority priority = domain.TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  }) async {
    await _ensureDefaultList();

    final now = DateTime.now();
    final trimmedTitle = title.trim();
    final id = _uuid.v4();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty');
    }

    final companion = db.TasksCompanion.insert(
      id: id,
      listId: defaultListId,
      title: trimmedTitle,
      description: Value(description?.trim()),
      priority: Value(priority.value),
      dueDate: Value(dueDate),
      createdAt: Value(now),
      updatedAt: Value(now),
      creationSource: Value(creationSource),
    );

    await _database.into(_database.tasks).insert(companion);

    return domain.Task(
      id: id,
      listId: defaultListId,
      title: trimmedTitle,
      description: description?.trim(),
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
    );
  }

  @override
  Future<domain.Task> createVoiceTask(VoiceTaskParseResult result) {
    final description = result.description?.isNotEmpty == true
        ? result.description
        : '识别内容: ${result.rawTranscript}';

    return createTask(
      title: result.title,
      description: description,
      dueDate: result.dueDate,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
    );
  }

  @override
  Future<void> deleteTask(String id) {
    return (_database.delete(
      _database.tasks,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> _ensureDefaultList() {
    final companion = db.TaskListsCompanion.insert(
      id: defaultListId,
      userId: defaultUserId,
      name: 'Inbox',
    );

    return _database
        .into(_database.taskLists)
        .insert(companion, mode: InsertMode.insertOrIgnore);
  }

  domain.Task _mapTask(db.Task row) {
    return domain.Task(
      id: row.id,
      listId: row.listId,
      title: row.title,
      description: row.description,
      priority: domain.TaskPriority.fromValue(row.priority),
      dueDate: row.dueDate,
      isCompleted: row.isCompleted,
      completedAt: row.completedAt,
      siyuanBlockId: row.siyuanBlockId,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      creationSource: row.creationSource,
    );
  }
}
