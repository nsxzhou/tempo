import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// 任务优先级枚举
enum TaskPriority {
  none(0),
  p0(1, '紧急'),
  p1(2, '高'),
  p2(3, '中'),
  p3(4, '低');

  final int value;
  final String? label;
  const TaskPriority(this.value, [this.label]);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.none,
    );
  }
}

/// 任务领域模型
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String listId,
    required String title,
    String? description,
    @Default(TaskPriority.none) TaskPriority priority,
    DateTime? dueDate,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    String? siyuanBlockId,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('text') String creationSource,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
