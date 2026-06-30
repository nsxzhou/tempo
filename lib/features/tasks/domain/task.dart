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
class Task {
  const Task({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    this.dueDate,
    this.isAllDay = false,
    this.isCompleted = false,
    this.completedAt,
    this.siyuanBlockId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.creationSource = 'text',
    this.tag,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.recurrenceCount,
    this.durationMin,
    this.recurrenceSeriesId,
    this.syncPending = false,
  });

  final String id;
  final String listId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool isAllDay;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? siyuanBlockId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String creationSource;
  final String? tag;
  final String? recurrenceRule;
  final DateTime? recurrenceEnd;
  final int? recurrenceCount;
  final int? durationMin;
  final String? recurrenceSeriesId;
  final bool syncPending;

  bool get isRecurring =>
      recurrenceRule != null && recurrenceRule!.trim().isNotEmpty;

  Task copyWith({
    String? id,
    String? listId,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isAllDay,
    bool? isCompleted,
    DateTime? completedAt,
    String? siyuanBlockId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creationSource,
    String? tag,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    int? recurrenceCount,
    int? durationMin,
    String? recurrenceSeriesId,
    bool? syncPending,
    bool clearDescription = false,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
    bool clearSiyuanBlockId = false,
    bool clearTag = false,
    bool clearRecurrenceRule = false,
    bool clearRecurrenceEnd = false,
    bool clearRecurrenceCount = false,
    bool clearDurationMin = false,
    bool clearRecurrenceSeriesId = false,
  }) {
    return Task(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isAllDay: isAllDay ?? this.isAllDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      siyuanBlockId:
          clearSiyuanBlockId ? null : (siyuanBlockId ?? this.siyuanBlockId),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creationSource: creationSource ?? this.creationSource,
      tag: clearTag ? null : (tag ?? this.tag),
      recurrenceRule: clearRecurrenceRule
          ? null
          : (recurrenceRule ?? this.recurrenceRule),
      recurrenceEnd: clearRecurrenceEnd
          ? null
          : (recurrenceEnd ?? this.recurrenceEnd),
      recurrenceCount: clearRecurrenceCount
          ? null
          : (recurrenceCount ?? this.recurrenceCount),
      durationMin:
          clearDurationMin ? null : (durationMin ?? this.durationMin),
      recurrenceSeriesId: clearRecurrenceSeriesId
          ? null
          : (recurrenceSeriesId ?? this.recurrenceSeriesId),
      syncPending: syncPending ?? this.syncPending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          id == other.id &&
          listId == other.listId &&
          title == other.title &&
          description == other.description &&
          priority == other.priority &&
          dueDate == other.dueDate &&
          isAllDay == other.isAllDay &&
          isCompleted == other.isCompleted &&
          completedAt == other.completedAt &&
          siyuanBlockId == other.siyuanBlockId &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          creationSource == other.creationSource &&
          tag == other.tag &&
          recurrenceRule == other.recurrenceRule &&
          recurrenceEnd == other.recurrenceEnd &&
          recurrenceCount == other.recurrenceCount &&
          durationMin == other.durationMin &&
          recurrenceSeriesId == other.recurrenceSeriesId &&
          syncPending == other.syncPending;

  @override
  int get hashCode => Object.hashAll([
    id,
    listId,
    title,
    description,
    priority,
    dueDate,
    isAllDay,
    isCompleted,
    completedAt,
    siyuanBlockId,
    sortOrder,
    createdAt,
    updatedAt,
    creationSource,
    tag,
    recurrenceRule,
    recurrenceEnd,
    recurrenceCount,
    durationMin,
    recurrenceSeriesId,
    syncPending,
  ]);
}

/// Task Supabase JSON 序列化扩展（snake_case 列名）。
extension TaskSupabase on Task {
  Map<String, dynamic> toSupabaseJson({required String userId}) => {
    'id': id,
    'list_id': listId,
    'user_id': userId,
    'title': title,
    'description': description,
    'priority': priority.value,
    'due_date': dueDate?.toUtc().toIso8601String(),
    'is_all_day': isAllDay,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'siyuan_block_id': siyuanBlockId,
    'sort_order': sortOrder,
    'creation_source': creationSource,
    'tag': tag,
    'recurrence_rule': recurrenceRule,
    'recurrence_end': recurrenceEnd?.toUtc().toIso8601String(),
    'recurrence_count': recurrenceCount,
    'duration_min': durationMin,
    'recurrence_series_id': recurrenceSeriesId,
  };

  static Task fromSupabaseJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    listId: json['list_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    priority: TaskPriority.fromValue(json['priority'] as int? ?? 0),
    dueDate: json['due_date'] != null
        ? DateTime.parse(json['due_date'] as String).toLocal()
        : null,
    isAllDay: json['is_all_day'] as bool? ?? false,
    isCompleted: json['is_completed'] as bool? ?? false,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String).toLocal()
        : null,
    siyuanBlockId: json['siyuan_block_id'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    creationSource: json['creation_source'] as String? ?? 'text',
    tag: json['tag'] as String?,
    recurrenceRule: json['recurrence_rule'] as String?,
    recurrenceEnd: json['recurrence_end'] != null
        ? DateTime.parse(json['recurrence_end'] as String).toLocal()
        : null,
    recurrenceCount: json['recurrence_count'] as int?,
    durationMin: json['duration_min'] as int?,
    recurrenceSeriesId: json['recurrence_series_id'] as String?,
    syncPending: false,
  );
}
