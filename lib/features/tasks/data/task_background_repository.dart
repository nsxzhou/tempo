import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../database/database.dart' as db;

class TaskBackground {
  final String taskId;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBackground({
    required this.taskId,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}

abstract class TaskBackgroundRepository {
  Stream<List<TaskBackground>> watchBackgrounds();

  Stream<TaskBackground?> watchBackground(String taskId);

  Future<TaskBackground?> getBackground(String taskId);

  Future<TaskBackground?> pickBackgroundImage(String taskId);

  Future<TaskBackground> setBackgroundFromFile({
    required String taskId,
    required String sourcePath,
  });

  Future<void> clearBackground(String taskId);
}

class LocalTaskBackgroundRepository implements TaskBackgroundRepository {
  static const int _maxImageDimension = 2560;
  static const int _imageQuality = 95;

  final db.AppDatabase _db;
  final ImagePicker _picker;
  final Future<Directory> Function() _documentsDirectory;

  LocalTaskBackgroundRepository({
    required db.AppDatabase db,
    ImagePicker? picker,
    Future<Directory> Function()? documentsDirectory,
  }) : _db = db,
       _picker = picker ?? ImagePicker(),
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  @override
  Stream<List<TaskBackground>> watchBackgrounds() {
    return _db
        .select(_db.taskBackgrounds)
        .watch()
        .map((rows) => rows.map(_mapBackground).toList(growable: false));
  }

  @override
  Stream<TaskBackground?> watchBackground(String taskId) {
    return (_db.select(_db.taskBackgrounds)
          ..where((t) => t.taskId.equals(taskId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapBackground(row));
  }

  @override
  Future<TaskBackground?> getBackground(String taskId) async {
    final row = await (_db.select(
      _db.taskBackgrounds,
    )..where((t) => t.taskId.equals(taskId))).getSingleOrNull();
    return row == null ? null : _mapBackground(row);
  }

  @override
  Future<TaskBackground?> pickBackgroundImage(String taskId) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxImageDimension.toDouble(),
      maxHeight: _maxImageDimension.toDouble(),
      imageQuality: _imageQuality,
    );
    if (file == null) return null;
    return setBackgroundFromFile(taskId: taskId, sourcePath: file.path);
  }

  @override
  Future<TaskBackground> setBackgroundFromFile({
    required String taskId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'File not found');
    }

    final existing = await getBackground(taskId);
    final destPath = await _copyIntoBackgroundDirectory(
      taskId: taskId,
      sourcePath: sourcePath,
    );
    final now = DateTime.now();

    await _db
        .into(_db.taskBackgrounds)
        .insertOnConflictUpdate(
          db.TaskBackgroundsCompanion(
            taskId: Value(taskId),
            imagePath: Value(destPath),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
          ),
        );

    await _deleteFileIfUnused(existing?.imagePath, exceptPath: destPath);

    return TaskBackground(
      taskId: taskId,
      imagePath: destPath,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Future<void> clearBackground(String taskId) async {
    final existing = await getBackground(taskId);
    await (_db.delete(
      _db.taskBackgrounds,
    )..where((t) => t.taskId.equals(taskId))).go();
    await _deleteFileIfUnused(existing?.imagePath);
  }

  Future<String> _copyIntoBackgroundDirectory({
    required String taskId,
    required String sourcePath,
  }) async {
    final docs = await _documentsDirectory();
    final dir = Directory(p.join(docs.path, 'task_backgrounds'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final safeTaskId = taskId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destPath = p.join(
      dir.path,
      '${safeTaskId}_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> _deleteFileIfUnused(String? path, {String? exceptPath}) async {
    if (path == null || path == exceptPath) return;
    final stillUsed =
        await (_db.select(
          _db.taskBackgrounds,
        )..where((t) => t.imagePath.equals(path))).getSingleOrNull() !=
        null;
    if (stillUsed) return;

    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  TaskBackground _mapBackground(db.TaskBackground row) {
    return TaskBackground(
      taskId: row.taskId,
      imagePath: row.imagePath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
