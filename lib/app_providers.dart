import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/database_provider.dart';

/// 任务列表 Provider（响应式查询本地数据库）
///
/// TODO: Phase 1 实现 Drift 响应式查询
final taskListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  // 返回空列表，后续实现 Drift select 查询
  return db.allTasks();
});
