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
    @Default(false) bool syncPending,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

/// Task Supabase JSON 序列化扩展（snake_case 列名）。
extension TaskSupabase on Task {
  /// 转换为 Supabase JSON（snake_case 列名）。
  Map<String, dynamic> toSupabaseJson({required String userId}) => {
        'id': id,
        'list_id': listId,
        'user_id': userId,
        'title': title,
        'description': description,
        'priority': priority.value,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'is_completed': isCompleted,
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'siyuan_block_id': siyuanBlockId,
        'sort_order': sortOrder,
        'creation_source': creationSource,
        // 不传 updated_at（由触发器管理）
        // 不传 created_at（由 DB 默认值管理，除非 upsert）
      };

  /// 从 Supabase JSON 构建 Task。
  static Task fromSupabaseJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        listId: json['list_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        priority: TaskPriority.fromValue(json['priority'] as int? ?? 0),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String).toLocal()
            : null,
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String).toLocal()
            : null,
        siyuanBlockId: json['siyuan_block_id'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        creationSource: json['creation_source'] as String? ?? 'text',
        syncPending: false, // 从云端读取的数据总是已同步的
      );
}
