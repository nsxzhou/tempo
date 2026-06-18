import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/database_provider.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/data/voice_recorder.dart';
import 'features/tasks/data/voice_task_service.dart';
import 'features/tasks/domain/task.dart';

const _defaultVoiceTaskEndpoint = String.fromEnvironment(
  'TEMPO_VOICE_TASK_ENDPOINT',
  defaultValue: 'http://127.0.0.1:54321/functions/v1/voice-task',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftTaskRepository(db);
});

final taskListProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks();
});

final voiceTaskServiceProvider = Provider<VoiceTaskService>((ref) {
  final dio = ref.watch(dioProvider);
  return DioVoiceTaskService(dio: dio, endpoint: _defaultVoiceTaskEndpoint);
});

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();
  ref.onDispose(() {
    recorder.dispose();
  });
  return recorder;
});
