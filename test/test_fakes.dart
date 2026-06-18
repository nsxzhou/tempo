import 'dart:async';
import 'dart:typed_data';

import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/data/task_repository.dart';
import 'package:tempo/features/tasks/data/voice_recorder.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/data/voice_task_service.dart';
import 'package:tempo/features/tasks/domain/task.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];
  final List<String> deletedTaskIds = [];
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();
  int _nextId = 0;

  @override
  Stream<List<Task>> watchTasks() {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.none,
    String creationSource = AppConstants.sourceText,
  }) async {
    final now = DateTime(2026, 6, 18, 9, _nextId);
    final task = Task(
      id: 'task-${_nextId++}',
      listId: DriftTaskRepository.defaultListId,
      title: title.trim(),
      description: description,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
    );
    tasks.insert(0, task);
    _emit();
    return task;
  }

  @override
  Future<Task> createVoiceTask(VoiceTaskParseResult result) {
    return createTask(
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task.copyWith(updatedAt: DateTime.now());
      _emit();
      return tasks[index];
    }
    throw StateError('Task not found: ${task.id}');
  }

  @override
  Future<Task> toggleComplete(String id) async {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw StateError('Task not found: $id');
    }
    final current = tasks[index];
    final now = DateTime.now();
    final toggled = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: !current.isCompleted ? now : null,
      updatedAt: now,
    );
    tasks[index] = toggled;
    _emit();
    return toggled;
  }

  @override
  Future<void> deleteTask(String id) async {
    deletedTaskIds.add(id);
    tasks.removeWhere((task) => task.id == id);
    _emit();
  }

  @override
  Stream<List<Task>> watchTasksByList(String listId) {
    scheduleMicrotask(() {
      _controller.add(tasks.where((t) => t.listId == listId).toList());
    });
    return _controller.stream;
  }

  @override
  Stream<List<Task>> watchTasksByDateRange(DateTime start, DateTime end) {
    scheduleMicrotask(() {
      _controller.add(
        tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end);
        }).toList(),
      );
    });
    return _controller.stream;
  }

  @override
  Future<Task?> getTaskById(String id) async {
    return tasks.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<void> pushPending() async {
    // Fake: 清除所有 syncPending 标记
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].syncPending) {
        tasks[i] = tasks[i].copyWith(syncPending: false);
      }
    }
    _emit();
  }

  Future<void> dispose() {
    return _controller.close();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(tasks));
    }
  }
}

class FakeVoiceTaskService implements VoiceTaskService {
  final VoiceTaskParseResult? result;
  final Object? error;
  final List<String> parsedFiles = [];

  FakeVoiceTaskService({this.result, this.error});

  @override
  Future<VoiceTaskParseResult> parseAudioFile(String path) async {
    parsedFiles.add(path);
    if (error != null) {
      throw error!;
    }
    return result!;
  }

  @override
  Future<VoiceTaskParseResult> parseAudioBytes(
    Uint8List bytes, {
    String filename = 'voice-task.m4a',
  }) async {
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

class FakeVoiceRecorder implements VoiceRecorder {
  final bool permission;
  final String? path;
  bool started = false;
  bool stopped = false;
  bool canceled = false;

  FakeVoiceRecorder({this.permission = true, this.path = '/tmp/voice.m4a'});

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<String?> stop() async {
    stopped = true;
    return path;
  }

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  @override
  Future<void> dispose() async {}
}
