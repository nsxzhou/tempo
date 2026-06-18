import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_list.freezed.dart';
part 'task_list.g.dart';

/// 任务列表领域模型
@freezed
class TaskList with _$TaskList {
  const factory TaskList({
    required String id,
    required String userId,
    required String name,
    @Default(0) int sortOrder,
    required DateTime createdAt,
  }) = _TaskList;

  factory TaskList.fromJson(Map<String, dynamic> json) =>
      _$TaskListFromJson(json);
}
