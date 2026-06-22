import 'package:drift/drift.dart';

/// 任务列表表
class TaskLists extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 同步待推送标记：true 表示本地写入但尚未推送到云端。
  BoolColumn get syncPending =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 任务表
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text().references(TaskLists, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  /// 优先级: 0=无, 1=P0(紧急), 2=P1(高), 3=P2(中), 4=P3(低)
  IntColumn get priority => integer().withDefault(const Constant(0))();

  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get siyuanBlockId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 创建来源: 'text' | 'siyuan' | 'voice' | 'ai'
  TextColumn get creationSource => text().withDefault(const Constant('text'))();

  /// 分类: 'work' | 'life' | null
  TextColumn get tag => text().nullable()();

  /// 同步待推送标记：true 表示本地写入但尚未推送到云端。
  BoolColumn get syncPending =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
