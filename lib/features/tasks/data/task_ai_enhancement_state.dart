import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskAiEnhancementStatus { pending, succeeded, failed }

abstract class TaskAiEnhancementTracker {
  void markPending(String taskId);

  void markSucceeded(String taskId);

  void markFailed(String taskId);

  void clear(String taskId);
}

class TaskAiEnhancementController
    extends StateNotifier<Map<String, TaskAiEnhancementStatus>>
    implements TaskAiEnhancementTracker {
  TaskAiEnhancementController() : super(const {});

  @override
  void markPending(String taskId) {
    state = {...state, taskId: TaskAiEnhancementStatus.pending};
  }

  @override
  void markSucceeded(String taskId) {
    state = {...state, taskId: TaskAiEnhancementStatus.succeeded};
  }

  @override
  void markFailed(String taskId) {
    state = {...state, taskId: TaskAiEnhancementStatus.failed};
  }

  @override
  void clear(String taskId) {
    final next = Map<String, TaskAiEnhancementStatus>.from(state)
      ..remove(taskId);
    state = next;
  }
}
