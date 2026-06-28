import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/features/tasks/data/streaming_voice_session.dart';
import 'package:tempo/features/tasks/data/task_background_repository.dart';
import 'package:tempo/features/tasks/data/task_repository.dart';
import 'package:tempo/features/tasks/data/text_parse_service.dart';
import 'package:tempo/features/tasks/data/voice_recorder.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/data/volcengine_streaming_asr.dart';
import 'package:tempo/features/tasks/domain/task.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];
  final List<String> deletedTaskIds = [];
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();
  int _nextId = 0;
  Object? createError;

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
    bool isAllDay = false,
    TaskPriority priority = TaskPriority.none,
    String creationSource = AppConstants.sourceText,
    String? tag,
  }) async {
    if (createError != null) {
      throw createError!;
    }
    final now = DateTime(2026, 6, 18, 9, _nextId);
    final task = Task(
      id: 'task-${_nextId++}',
      listId: AppConstants.defaultListId,
      title: title.trim(),
      description: description,
      priority: priority,
      dueDate: dueDate,
      isAllDay: isAllDay,
      createdAt: now,
      updatedAt: now,
      creationSource: creationSource,
      tag: tag,
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
      isAllDay: result.isAllDay,
      priority: result.priority,
      creationSource: AppConstants.sourceVoice,
      tag: result.tag,
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
  Future<Task?> getTaskById(String id) async {
    return tasks.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<void> pushPending() async {
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].syncPending) {
        tasks[i] = tasks[i].copyWith(syncPending: false);
      }
    }
    _emit();
  }

  @override
  void requestRefresh() {
    // 测试 fake 不触发真实远端刷新。
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

class FakeTaskBackgroundRepository implements TaskBackgroundRepository {
  @override
  Stream<List<TaskBackground>> watchBackgrounds() => const Stream.empty();

  @override
  Stream<TaskBackground?> watchBackground(String taskId) => Stream.value(null);

  @override
  Future<TaskBackground?> getBackground(String taskId) async => null;

  @override
  Future<TaskBackground?> pickBackgroundImage(String taskId) async => null;

  @override
  Future<TaskBackground> setBackgroundFromFile({
    required String taskId,
    required String sourcePath,
  }) {
    throw UnsupportedError('Fake does not create task backgrounds');
  }

  @override
  Future<void> clearBackground(String taskId) async {}
}

class FakeVoiceRecorder implements VoiceRecorder {
  final bool permission;
  final StreamController<Uint8List>? audioController;

  bool started = false;
  bool stopped = false;
  bool canceled = false;

  FakeVoiceRecorder({this.permission = true, this.audioController});

  @override
  Stream<Uint8List>? get audioStream => audioController?.stream;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  @override
  Future<void> dispose() async {}
}

class FakeVolcengineStreamingAsr implements VolcengineStreamingAsr {
  final String finalTranscript;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  String _current = '';

  FakeVolcengineStreamingAsr({this.finalTranscript = '明天下午三点开会'});

  @override
  String get currentTranscript => _current;

  @override
  Stream<String> get transcriptStream => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  void sendAudio(Uint8List chunk) {}

  @override
  Future<String> finish() async {
    _current = finalTranscript;
    _controller.add(finalTranscript);
    return finalTranscript;
  }

  @override
  Future<void> cancel() async {}

  Future<void> dispose() => _controller.close();
}

class FakeStreamingVoiceSession implements StreamingVoiceSession {
  final String finalTranscript;
  final bool permission;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  String _current = '';

  bool prepared = false;
  bool started = false;
  bool stopped = false;
  bool recording = false;

  FakeStreamingVoiceSession({
    this.finalTranscript = '明天下午三点提交设计稿，优先级高',
    this.permission = true,
  });

  @override
  String get currentTranscript => _current;

  @override
  bool get isRecording => recording;

  @override
  Stream<String> get transcriptStream => _controller.stream;

  @override
  Future<void> prepare() async {
    prepared = true;
  }

  @override
  Future<void> startRecording() async {
    if (!permission) {
      throw const StreamingVoiceException('需要麦克风权限才能语音创建任务。');
    }
    started = true;
    recording = true;
    _current = '明天下午';
    _controller.add(_current);
  }

  @override
  Future<void> start() async {
    await prepare();
    await startRecording();
  }

  @override
  Future<String> stopAndGetTranscript() async {
    stopped = true;
    recording = false;
    _current = finalTranscript;
    _controller.add(finalTranscript);
    return finalTranscript;
  }

  @override
  Future<void> disposeSession() async {
    prepared = false;
  }

  @override
  Future<void> cancel() async {
    recording = false;
    _current = '';
  }

  Future<void> dispose() => _controller.close();
}

class FakeTextParseService extends TextParseService {
  VoiceTaskParseResult? result;
  int parseCallCount = 0;

  FakeTextParseService({this.result})
    : super(dio: Dio(), endpoint: 'http://test/parse-task');

  @override
  Future<VoiceTaskParseResult?> parseText(String text) async {
    parseCallCount++;
    return result;
  }
}
