/// 按 taskId 过滤列表的扩展方法。
library;

/// 按 [taskId] 过滤列表，返回匹配项的列表。
///
/// 用于从 completions / exceptions 等全量列表中快速提取
/// 某个任务的子集，消除重复的 `.where((x) => x.taskId == id)` 模式。
extension TaskFilterX<T> on List<T> {
  /// 返回所有 [getTaskId] 匹配 [taskId] 的元素。
  List<T> forTask(String taskId, String Function(T) getTaskId) {
    return where((item) => getTaskId(item) == taskId).toList();
  }
}
