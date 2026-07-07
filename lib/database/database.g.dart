// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TaskListsTable extends TaskLists
    with TableInfo<$TaskListsTable, TaskList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    sortOrder,
    createdAt,
    syncPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
    );
  }

  @override
  $TaskListsTable createAlias(String alias) {
    return $TaskListsTable(attachedDatabase, alias);
  }
}

class TaskList extends DataClass implements Insertable<TaskList> {
  final String id;
  final String userId;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  /// 同步待推送标记：true 表示本地写入但尚未推送到云端。
  final bool syncPending;
  const TaskList({
    required this.id,
    required this.userId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.syncPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_pending'] = Variable<bool>(syncPending);
    return map;
  }

  TaskListsCompanion toCompanion(bool nullToAbsent) {
    return TaskListsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      syncPending: Value(syncPending),
    );
  }

  factory TaskList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskList(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncPending': serializer.toJson<bool>(syncPending),
    };
  }

  TaskList copyWith({
    String? id,
    String? userId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
    bool? syncPending,
  }) => TaskList(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    syncPending: syncPending ?? this.syncPending,
  );
  TaskList copyWithCompanion(TaskListsCompanion data) {
    return TaskList(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskList(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, name, sortOrder, createdAt, syncPending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskList &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.syncPending == this.syncPending);
}

class TaskListsCompanion extends UpdateCompanion<TaskList> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TaskListsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskListsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name);
  static Insertable<TaskList> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<bool>? syncPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (syncPending != null) 'sync_pending': syncPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskListsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<bool>? syncPending,
    Value<int>? rowid,
  }) {
    return TaskListsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      syncPending: syncPending ?? this.syncPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskListsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_lists (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siyuanBlockIdMeta = const VerificationMeta(
    'siyuanBlockId',
  );
  @override
  late final GeneratedColumn<String> siyuanBlockId = GeneratedColumn<String>(
    'siyuan_block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _creationSourceMeta = const VerificationMeta(
    'creationSource',
  );
  @override
  late final GeneratedColumn<String> creationSource = GeneratedColumn<String>(
    'creation_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceEndMeta = const VerificationMeta(
    'recurrenceEnd',
  );
  @override
  late final GeneratedColumn<DateTime> recurrenceEnd =
      GeneratedColumn<DateTime>(
        'recurrence_end',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceCountMeta = const VerificationMeta(
    'recurrenceCount',
  );
  @override
  late final GeneratedColumn<int> recurrenceCount = GeneratedColumn<int>(
    'recurrence_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceSeriesIdMeta =
      const VerificationMeta('recurrenceSeriesId');
  @override
  late final GeneratedColumn<String> recurrenceSeriesId =
      GeneratedColumn<String>(
        'recurrence_series_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('siyuan_block_id')) {
      context.handle(
        _siyuanBlockIdMeta,
        siyuanBlockId.isAcceptableOrUnknown(
          data['siyuan_block_id']!,
          _siyuanBlockIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('creation_source')) {
      context.handle(
        _creationSourceMeta,
        creationSource.isAcceptableOrUnknown(
          data['creation_source']!,
          _creationSourceMeta,
        ),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_end')) {
      context.handle(
        _recurrenceEndMeta,
        recurrenceEnd.isAcceptableOrUnknown(
          data['recurrence_end']!,
          _recurrenceEndMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_count')) {
      context.handle(
        _recurrenceCountMeta,
        recurrenceCount.isAcceptableOrUnknown(
          data['recurrence_count']!,
          _recurrenceCountMeta,
        ),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_series_id')) {
      context.handle(
        _recurrenceSeriesIdMeta,
        recurrenceSeriesId.isAcceptableOrUnknown(
          data['recurrence_series_id']!,
          _recurrenceSeriesIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      siyuanBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}siyuan_block_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      creationSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creation_source'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      recurrenceEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recurrence_end'],
      ),
      recurrenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_count'],
      ),
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      ),
      recurrenceSeriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_series_id'],
      ),
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String listId;
  final String title;
  final String? description;

  /// 优先级: 0=无, 1=P0(紧急), 2=P1(高), 3=P2(中), 4=P3(低)
  final int priority;
  final DateTime? dueDate;
  final bool isAllDay;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? siyuanBlockId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 创建来源: 'text' | 'siyuan' | 'voice' | 'ai'
  final String creationSource;

  /// 分类: 'work' | 'life' | null
  final String? tag;

  /// RRULE 字符串，null = 非重复任务
  final String? recurrenceRule;
  final DateTime? recurrenceEnd;
  final int? recurrenceCount;
  final int? durationMin;
  final String? recurrenceSeriesId;

  /// 同步待推送标记：true 表示本地写入但尚未推送到云端。
  final bool syncPending;
  const Task({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    required this.isAllDay,
    required this.isCompleted,
    this.completedAt,
    this.siyuanBlockId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.creationSource,
    this.tag,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.recurrenceCount,
    this.durationMin,
    this.recurrenceSeriesId,
    required this.syncPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || siyuanBlockId != null) {
      map['siyuan_block_id'] = Variable<String>(siyuanBlockId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['creation_source'] = Variable<String>(creationSource);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || recurrenceEnd != null) {
      map['recurrence_end'] = Variable<DateTime>(recurrenceEnd);
    }
    if (!nullToAbsent || recurrenceCount != null) {
      map['recurrence_count'] = Variable<int>(recurrenceCount);
    }
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    if (!nullToAbsent || recurrenceSeriesId != null) {
      map['recurrence_series_id'] = Variable<String>(recurrenceSeriesId);
    }
    map['sync_pending'] = Variable<bool>(syncPending);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      listId: Value(listId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isAllDay: Value(isAllDay),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      siyuanBlockId: siyuanBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(siyuanBlockId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      creationSource: Value(creationSource),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      recurrenceEnd: recurrenceEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceEnd),
      recurrenceCount: recurrenceCount == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceCount),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      recurrenceSeriesId: recurrenceSeriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceSeriesId),
      syncPending: Value(syncPending),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      siyuanBlockId: serializer.fromJson<String?>(json['siyuanBlockId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      creationSource: serializer.fromJson<String>(json['creationSource']),
      tag: serializer.fromJson<String?>(json['tag']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      recurrenceEnd: serializer.fromJson<DateTime?>(json['recurrenceEnd']),
      recurrenceCount: serializer.fromJson<int?>(json['recurrenceCount']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      recurrenceSeriesId: serializer.fromJson<String?>(
        json['recurrenceSeriesId'],
      ),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'siyuanBlockId': serializer.toJson<String?>(siyuanBlockId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'creationSource': serializer.toJson<String>(creationSource),
      'tag': serializer.toJson<String?>(tag),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'recurrenceEnd': serializer.toJson<DateTime?>(recurrenceEnd),
      'recurrenceCount': serializer.toJson<int?>(recurrenceCount),
      'durationMin': serializer.toJson<int?>(durationMin),
      'recurrenceSeriesId': serializer.toJson<String?>(recurrenceSeriesId),
      'syncPending': serializer.toJson<bool>(syncPending),
    };
  }

  Task copyWith({
    String? id,
    String? listId,
    String? title,
    Value<String?> description = const Value.absent(),
    int? priority,
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isAllDay,
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> siyuanBlockId = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creationSource,
    Value<String?> tag = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<DateTime?> recurrenceEnd = const Value.absent(),
    Value<int?> recurrenceCount = const Value.absent(),
    Value<int?> durationMin = const Value.absent(),
    Value<String?> recurrenceSeriesId = const Value.absent(),
    bool? syncPending,
  }) => Task(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isAllDay: isAllDay ?? this.isAllDay,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    siyuanBlockId: siyuanBlockId.present
        ? siyuanBlockId.value
        : this.siyuanBlockId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    creationSource: creationSource ?? this.creationSource,
    tag: tag.present ? tag.value : this.tag,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    recurrenceEnd: recurrenceEnd.present
        ? recurrenceEnd.value
        : this.recurrenceEnd,
    recurrenceCount: recurrenceCount.present
        ? recurrenceCount.value
        : this.recurrenceCount,
    durationMin: durationMin.present ? durationMin.value : this.durationMin,
    recurrenceSeriesId: recurrenceSeriesId.present
        ? recurrenceSeriesId.value
        : this.recurrenceSeriesId,
    syncPending: syncPending ?? this.syncPending,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      siyuanBlockId: data.siyuanBlockId.present
          ? data.siyuanBlockId.value
          : this.siyuanBlockId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      creationSource: data.creationSource.present
          ? data.creationSource.value
          : this.creationSource,
      tag: data.tag.present ? data.tag.value : this.tag,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      recurrenceEnd: data.recurrenceEnd.present
          ? data.recurrenceEnd.value
          : this.recurrenceEnd,
      recurrenceCount: data.recurrenceCount.present
          ? data.recurrenceCount.value
          : this.recurrenceCount,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      recurrenceSeriesId: data.recurrenceSeriesId.present
          ? data.recurrenceSeriesId.value
          : this.recurrenceSeriesId,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('siyuanBlockId: $siyuanBlockId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('creationSource: $creationSource, ')
          ..write('tag: $tag, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('recurrenceEnd: $recurrenceEnd, ')
          ..write('recurrenceCount: $recurrenceCount, ')
          ..write('durationMin: $durationMin, ')
          ..write('recurrenceSeriesId: $recurrenceSeriesId, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.isAllDay == this.isAllDay &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.siyuanBlockId == this.siyuanBlockId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.creationSource == this.creationSource &&
          other.tag == this.tag &&
          other.recurrenceRule == this.recurrenceRule &&
          other.recurrenceEnd == this.recurrenceEnd &&
          other.recurrenceCount == this.recurrenceCount &&
          other.durationMin == this.durationMin &&
          other.recurrenceSeriesId == this.recurrenceSeriesId &&
          other.syncPending == this.syncPending);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<DateTime?> dueDate;
  final Value<bool> isAllDay;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String?> siyuanBlockId;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> creationSource;
  final Value<String?> tag;
  final Value<String?> recurrenceRule;
  final Value<DateTime?> recurrenceEnd;
  final Value<int?> recurrenceCount;
  final Value<int?> durationMin;
  final Value<String?> recurrenceSeriesId;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.siyuanBlockId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.creationSource = const Value.absent(),
    this.tag = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.recurrenceEnd = const Value.absent(),
    this.recurrenceCount = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.recurrenceSeriesId = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String listId,
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.siyuanBlockId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.creationSource = const Value.absent(),
    this.tag = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.recurrenceEnd = const Value.absent(),
    this.recurrenceCount = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.recurrenceSeriesId = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       title = Value(title);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<DateTime>? dueDate,
    Expression<bool>? isAllDay,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? siyuanBlockId,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? creationSource,
    Expression<String>? tag,
    Expression<String>? recurrenceRule,
    Expression<DateTime>? recurrenceEnd,
    Expression<int>? recurrenceCount,
    Expression<int>? durationMin,
    Expression<String>? recurrenceSeriesId,
    Expression<bool>? syncPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (siyuanBlockId != null) 'siyuan_block_id': siyuanBlockId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (creationSource != null) 'creation_source': creationSource,
      if (tag != null) 'tag': tag,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (recurrenceEnd != null) 'recurrence_end': recurrenceEnd,
      if (recurrenceCount != null) 'recurrence_count': recurrenceCount,
      if (durationMin != null) 'duration_min': durationMin,
      if (recurrenceSeriesId != null)
        'recurrence_series_id': recurrenceSeriesId,
      if (syncPending != null) 'sync_pending': syncPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? priority,
    Value<DateTime?>? dueDate,
    Value<bool>? isAllDay,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<String?>? siyuanBlockId,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? creationSource,
    Value<String?>? tag,
    Value<String?>? recurrenceRule,
    Value<DateTime?>? recurrenceEnd,
    Value<int?>? recurrenceCount,
    Value<int?>? durationMin,
    Value<String?>? recurrenceSeriesId,
    Value<bool>? syncPending,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isAllDay: isAllDay ?? this.isAllDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      siyuanBlockId: siyuanBlockId ?? this.siyuanBlockId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creationSource: creationSource ?? this.creationSource,
      tag: tag ?? this.tag,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceEnd: recurrenceEnd ?? this.recurrenceEnd,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      durationMin: durationMin ?? this.durationMin,
      recurrenceSeriesId: recurrenceSeriesId ?? this.recurrenceSeriesId,
      syncPending: syncPending ?? this.syncPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (siyuanBlockId.present) {
      map['siyuan_block_id'] = Variable<String>(siyuanBlockId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (creationSource.present) {
      map['creation_source'] = Variable<String>(creationSource.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (recurrenceEnd.present) {
      map['recurrence_end'] = Variable<DateTime>(recurrenceEnd.value);
    }
    if (recurrenceCount.present) {
      map['recurrence_count'] = Variable<int>(recurrenceCount.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (recurrenceSeriesId.present) {
      map['recurrence_series_id'] = Variable<String>(recurrenceSeriesId.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('siyuanBlockId: $siyuanBlockId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('creationSource: $creationSource, ')
          ..write('tag: $tag, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('recurrenceEnd: $recurrenceEnd, ')
          ..write('recurrenceCount: $recurrenceCount, ')
          ..write('durationMin: $durationMin, ')
          ..write('recurrenceSeriesId: $recurrenceSeriesId, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRecurrenceExceptionsTable extends TaskRecurrenceExceptions
    with TableInfo<$TaskRecurrenceExceptionsTable, TaskRecurrenceException> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRecurrenceExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exceptionDateMeta = const VerificationMeta(
    'exceptionDate',
  );
  @override
  late final GeneratedColumn<DateTime> exceptionDate =
      GeneratedColumn<DateTime>(
        'exception_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _overrideDueMeta = const VerificationMeta(
    'overrideDue',
  );
  @override
  late final GeneratedColumn<DateTime> overrideDue = GeneratedColumn<DateTime>(
    'override_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideTitleMeta = const VerificationMeta(
    'overrideTitle',
  );
  @override
  late final GeneratedColumn<String> overrideTitle = GeneratedColumn<String>(
    'override_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCancelledMeta = const VerificationMeta(
    'isCancelled',
  );
  @override
  late final GeneratedColumn<bool> isCancelled = GeneratedColumn<bool>(
    'is_cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    exceptionDate,
    overrideDue,
    overrideTitle,
    isCancelled,
    syncPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_recurrence_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRecurrenceException> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('exception_date')) {
      context.handle(
        _exceptionDateMeta,
        exceptionDate.isAcceptableOrUnknown(
          data['exception_date']!,
          _exceptionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exceptionDateMeta);
    }
    if (data.containsKey('override_due')) {
      context.handle(
        _overrideDueMeta,
        overrideDue.isAcceptableOrUnknown(
          data['override_due']!,
          _overrideDueMeta,
        ),
      );
    }
    if (data.containsKey('override_title')) {
      context.handle(
        _overrideTitleMeta,
        overrideTitle.isAcceptableOrUnknown(
          data['override_title']!,
          _overrideTitleMeta,
        ),
      );
    }
    if (data.containsKey('is_cancelled')) {
      context.handle(
        _isCancelledMeta,
        isCancelled.isAcceptableOrUnknown(
          data['is_cancelled']!,
          _isCancelledMeta,
        ),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, exceptionDate};
  @override
  TaskRecurrenceException map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRecurrenceException(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      exceptionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exception_date'],
      )!,
      overrideDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}override_due'],
      ),
      overrideTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_title'],
      ),
      isCancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cancelled'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
    );
  }

  @override
  $TaskRecurrenceExceptionsTable createAlias(String alias) {
    return $TaskRecurrenceExceptionsTable(attachedDatabase, alias);
  }
}

class TaskRecurrenceException extends DataClass
    implements Insertable<TaskRecurrenceException> {
  final String taskId;
  final DateTime exceptionDate;
  final DateTime? overrideDue;
  final String? overrideTitle;
  final bool isCancelled;
  final bool syncPending;
  const TaskRecurrenceException({
    required this.taskId,
    required this.exceptionDate,
    this.overrideDue,
    this.overrideTitle,
    required this.isCancelled,
    required this.syncPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['exception_date'] = Variable<DateTime>(exceptionDate);
    if (!nullToAbsent || overrideDue != null) {
      map['override_due'] = Variable<DateTime>(overrideDue);
    }
    if (!nullToAbsent || overrideTitle != null) {
      map['override_title'] = Variable<String>(overrideTitle);
    }
    map['is_cancelled'] = Variable<bool>(isCancelled);
    map['sync_pending'] = Variable<bool>(syncPending);
    return map;
  }

  TaskRecurrenceExceptionsCompanion toCompanion(bool nullToAbsent) {
    return TaskRecurrenceExceptionsCompanion(
      taskId: Value(taskId),
      exceptionDate: Value(exceptionDate),
      overrideDue: overrideDue == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideDue),
      overrideTitle: overrideTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideTitle),
      isCancelled: Value(isCancelled),
      syncPending: Value(syncPending),
    );
  }

  factory TaskRecurrenceException.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRecurrenceException(
      taskId: serializer.fromJson<String>(json['taskId']),
      exceptionDate: serializer.fromJson<DateTime>(json['exceptionDate']),
      overrideDue: serializer.fromJson<DateTime?>(json['overrideDue']),
      overrideTitle: serializer.fromJson<String?>(json['overrideTitle']),
      isCancelled: serializer.fromJson<bool>(json['isCancelled']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'exceptionDate': serializer.toJson<DateTime>(exceptionDate),
      'overrideDue': serializer.toJson<DateTime?>(overrideDue),
      'overrideTitle': serializer.toJson<String?>(overrideTitle),
      'isCancelled': serializer.toJson<bool>(isCancelled),
      'syncPending': serializer.toJson<bool>(syncPending),
    };
  }

  TaskRecurrenceException copyWith({
    String? taskId,
    DateTime? exceptionDate,
    Value<DateTime?> overrideDue = const Value.absent(),
    Value<String?> overrideTitle = const Value.absent(),
    bool? isCancelled,
    bool? syncPending,
  }) => TaskRecurrenceException(
    taskId: taskId ?? this.taskId,
    exceptionDate: exceptionDate ?? this.exceptionDate,
    overrideDue: overrideDue.present ? overrideDue.value : this.overrideDue,
    overrideTitle: overrideTitle.present
        ? overrideTitle.value
        : this.overrideTitle,
    isCancelled: isCancelled ?? this.isCancelled,
    syncPending: syncPending ?? this.syncPending,
  );
  TaskRecurrenceException copyWithCompanion(
    TaskRecurrenceExceptionsCompanion data,
  ) {
    return TaskRecurrenceException(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      exceptionDate: data.exceptionDate.present
          ? data.exceptionDate.value
          : this.exceptionDate,
      overrideDue: data.overrideDue.present
          ? data.overrideDue.value
          : this.overrideDue,
      overrideTitle: data.overrideTitle.present
          ? data.overrideTitle.value
          : this.overrideTitle,
      isCancelled: data.isCancelled.present
          ? data.isCancelled.value
          : this.isCancelled,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceException(')
          ..write('taskId: $taskId, ')
          ..write('exceptionDate: $exceptionDate, ')
          ..write('overrideDue: $overrideDue, ')
          ..write('overrideTitle: $overrideTitle, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    exceptionDate,
    overrideDue,
    overrideTitle,
    isCancelled,
    syncPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRecurrenceException &&
          other.taskId == this.taskId &&
          other.exceptionDate == this.exceptionDate &&
          other.overrideDue == this.overrideDue &&
          other.overrideTitle == this.overrideTitle &&
          other.isCancelled == this.isCancelled &&
          other.syncPending == this.syncPending);
}

class TaskRecurrenceExceptionsCompanion
    extends UpdateCompanion<TaskRecurrenceException> {
  final Value<String> taskId;
  final Value<DateTime> exceptionDate;
  final Value<DateTime?> overrideDue;
  final Value<String?> overrideTitle;
  final Value<bool> isCancelled;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TaskRecurrenceExceptionsCompanion({
    this.taskId = const Value.absent(),
    this.exceptionDate = const Value.absent(),
    this.overrideDue = const Value.absent(),
    this.overrideTitle = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRecurrenceExceptionsCompanion.insert({
    required String taskId,
    required DateTime exceptionDate,
    this.overrideDue = const Value.absent(),
    this.overrideTitle = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       exceptionDate = Value(exceptionDate);
  static Insertable<TaskRecurrenceException> custom({
    Expression<String>? taskId,
    Expression<DateTime>? exceptionDate,
    Expression<DateTime>? overrideDue,
    Expression<String>? overrideTitle,
    Expression<bool>? isCancelled,
    Expression<bool>? syncPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (exceptionDate != null) 'exception_date': exceptionDate,
      if (overrideDue != null) 'override_due': overrideDue,
      if (overrideTitle != null) 'override_title': overrideTitle,
      if (isCancelled != null) 'is_cancelled': isCancelled,
      if (syncPending != null) 'sync_pending': syncPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRecurrenceExceptionsCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? exceptionDate,
    Value<DateTime?>? overrideDue,
    Value<String?>? overrideTitle,
    Value<bool>? isCancelled,
    Value<bool>? syncPending,
    Value<int>? rowid,
  }) {
    return TaskRecurrenceExceptionsCompanion(
      taskId: taskId ?? this.taskId,
      exceptionDate: exceptionDate ?? this.exceptionDate,
      overrideDue: overrideDue ?? this.overrideDue,
      overrideTitle: overrideTitle ?? this.overrideTitle,
      isCancelled: isCancelled ?? this.isCancelled,
      syncPending: syncPending ?? this.syncPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (exceptionDate.present) {
      map['exception_date'] = Variable<DateTime>(exceptionDate.value);
    }
    if (overrideDue.present) {
      map['override_due'] = Variable<DateTime>(overrideDue.value);
    }
    if (overrideTitle.present) {
      map['override_title'] = Variable<String>(overrideTitle.value);
    }
    if (isCancelled.present) {
      map['is_cancelled'] = Variable<bool>(isCancelled.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceExceptionsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('exceptionDate: $exceptionDate, ')
          ..write('overrideDue: $overrideDue, ')
          ..write('overrideTitle: $overrideTitle, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskCompletionsTable extends TaskCompletions
    with TableInfo<$TaskCompletionsTable, TaskCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceDate =
      GeneratedColumn<DateTime>(
        'occurrence_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    occurrenceDate,
    completedAt,
    syncPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, occurrenceDate};
  @override
  TaskCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCompletion(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_date'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
    );
  }

  @override
  $TaskCompletionsTable createAlias(String alias) {
    return $TaskCompletionsTable(attachedDatabase, alias);
  }
}

class TaskCompletion extends DataClass implements Insertable<TaskCompletion> {
  final String taskId;
  final DateTime occurrenceDate;
  final DateTime completedAt;
  final bool syncPending;
  const TaskCompletion({
    required this.taskId,
    required this.occurrenceDate,
    required this.completedAt,
    required this.syncPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['occurrence_date'] = Variable<DateTime>(occurrenceDate);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['sync_pending'] = Variable<bool>(syncPending);
    return map;
  }

  TaskCompletionsCompanion toCompanion(bool nullToAbsent) {
    return TaskCompletionsCompanion(
      taskId: Value(taskId),
      occurrenceDate: Value(occurrenceDate),
      completedAt: Value(completedAt),
      syncPending: Value(syncPending),
    );
  }

  factory TaskCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCompletion(
      taskId: serializer.fromJson<String>(json['taskId']),
      occurrenceDate: serializer.fromJson<DateTime>(json['occurrenceDate']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'occurrenceDate': serializer.toJson<DateTime>(occurrenceDate),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'syncPending': serializer.toJson<bool>(syncPending),
    };
  }

  TaskCompletion copyWith({
    String? taskId,
    DateTime? occurrenceDate,
    DateTime? completedAt,
    bool? syncPending,
  }) => TaskCompletion(
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    completedAt: completedAt ?? this.completedAt,
    syncPending: syncPending ?? this.syncPending,
  );
  TaskCompletion copyWithCompanion(TaskCompletionsCompanion data) {
    return TaskCompletion(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletion(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(taskId, occurrenceDate, completedAt, syncPending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCompletion &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.completedAt == this.completedAt &&
          other.syncPending == this.syncPending);
}

class TaskCompletionsCompanion extends UpdateCompanion<TaskCompletion> {
  final Value<String> taskId;
  final Value<DateTime> occurrenceDate;
  final Value<DateTime> completedAt;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TaskCompletionsCompanion({
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskCompletionsCompanion.insert({
    required String taskId,
    required DateTime occurrenceDate,
    this.completedAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       occurrenceDate = Value(occurrenceDate);
  static Insertable<TaskCompletion> custom({
    Expression<String>? taskId,
    Expression<DateTime>? occurrenceDate,
    Expression<DateTime>? completedAt,
    Expression<bool>? syncPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncPending != null) 'sync_pending': syncPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskCompletionsCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? occurrenceDate,
    Value<DateTime>? completedAt,
    Value<bool>? syncPending,
    Value<int>? rowid,
  }) {
    return TaskCompletionsCompanion(
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      completedAt: completedAt ?? this.completedAt,
      syncPending: syncPending ?? this.syncPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<DateTime>(occurrenceDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletionsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskDeletionOutboxTable extends TaskDeletionOutbox
    with TableInfo<$TaskDeletionOutboxTable, TaskDeletionOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskDeletionOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, deletedAt, syncPending];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_deletion_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskDeletionOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  TaskDeletionOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskDeletionOutboxData(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
    );
  }

  @override
  $TaskDeletionOutboxTable createAlias(String alias) {
    return $TaskDeletionOutboxTable(attachedDatabase, alias);
  }
}

class TaskDeletionOutboxData extends DataClass
    implements Insertable<TaskDeletionOutboxData> {
  final String taskId;
  final DateTime deletedAt;
  final bool syncPending;
  const TaskDeletionOutboxData({
    required this.taskId,
    required this.deletedAt,
    required this.syncPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    map['sync_pending'] = Variable<bool>(syncPending);
    return map;
  }

  TaskDeletionOutboxCompanion toCompanion(bool nullToAbsent) {
    return TaskDeletionOutboxCompanion(
      taskId: Value(taskId),
      deletedAt: Value(deletedAt),
      syncPending: Value(syncPending),
    );
  }

  factory TaskDeletionOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskDeletionOutboxData(
      taskId: serializer.fromJson<String>(json['taskId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
      'syncPending': serializer.toJson<bool>(syncPending),
    };
  }

  TaskDeletionOutboxData copyWith({
    String? taskId,
    DateTime? deletedAt,
    bool? syncPending,
  }) => TaskDeletionOutboxData(
    taskId: taskId ?? this.taskId,
    deletedAt: deletedAt ?? this.deletedAt,
    syncPending: syncPending ?? this.syncPending,
  );
  TaskDeletionOutboxData copyWithCompanion(TaskDeletionOutboxCompanion data) {
    return TaskDeletionOutboxData(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskDeletionOutboxData(')
          ..write('taskId: $taskId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, deletedAt, syncPending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskDeletionOutboxData &&
          other.taskId == this.taskId &&
          other.deletedAt == this.deletedAt &&
          other.syncPending == this.syncPending);
}

class TaskDeletionOutboxCompanion
    extends UpdateCompanion<TaskDeletionOutboxData> {
  final Value<String> taskId;
  final Value<DateTime> deletedAt;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TaskDeletionOutboxCompanion({
    this.taskId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskDeletionOutboxCompanion.insert({
    required String taskId,
    this.deletedAt = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId);
  static Insertable<TaskDeletionOutboxData> custom({
    Expression<String>? taskId,
    Expression<DateTime>? deletedAt,
    Expression<bool>? syncPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncPending != null) 'sync_pending': syncPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskDeletionOutboxCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? deletedAt,
    Value<bool>? syncPending,
    Value<int>? rowid,
  }) {
    return TaskDeletionOutboxCompanion(
      taskId: taskId ?? this.taskId,
      deletedAt: deletedAt ?? this.deletedAt,
      syncPending: syncPending ?? this.syncPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskDeletionOutboxCompanion(')
          ..write('taskId: $taskId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskBackgroundsTable extends TaskBackgrounds
    with TableInfo<$TaskBackgroundsTable, TaskBackground> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskBackgroundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    imagePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_backgrounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskBackground> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  TaskBackground map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskBackground(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TaskBackgroundsTable createAlias(String alias) {
    return $TaskBackgroundsTable(attachedDatabase, alias);
  }
}

class TaskBackground extends DataClass implements Insertable<TaskBackground> {
  final String taskId;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TaskBackground({
    required this.taskId,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['image_path'] = Variable<String>(imagePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TaskBackgroundsCompanion toCompanion(bool nullToAbsent) {
    return TaskBackgroundsCompanion(
      taskId: Value(taskId),
      imagePath: Value(imagePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskBackground.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskBackground(
      taskId: serializer.fromJson<String>(json['taskId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'imagePath': serializer.toJson<String>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TaskBackground copyWith({
    String? taskId,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskBackground(
    taskId: taskId ?? this.taskId,
    imagePath: imagePath ?? this.imagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskBackground copyWithCompanion(TaskBackgroundsCompanion data) {
    return TaskBackground(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskBackground(')
          ..write('taskId: $taskId, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, imagePath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskBackground &&
          other.taskId == this.taskId &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaskBackgroundsCompanion extends UpdateCompanion<TaskBackground> {
  final Value<String> taskId;
  final Value<String> imagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TaskBackgroundsCompanion({
    this.taskId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskBackgroundsCompanion.insert({
    required String taskId,
    required String imagePath,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       imagePath = Value(imagePath);
  static Insertable<TaskBackground> custom({
    Expression<String>? taskId,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskBackgroundsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? imagePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TaskBackgroundsCompanion(
      taskId: taskId ?? this.taskId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskBackgroundsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskListsTable taskLists = $TaskListsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskRecurrenceExceptionsTable taskRecurrenceExceptions =
      $TaskRecurrenceExceptionsTable(this);
  late final $TaskCompletionsTable taskCompletions = $TaskCompletionsTable(
    this,
  );
  late final $TaskDeletionOutboxTable taskDeletionOutbox =
      $TaskDeletionOutboxTable(this);
  late final $TaskBackgroundsTable taskBackgrounds = $TaskBackgroundsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskLists,
    tasks,
    taskRecurrenceExceptions,
    taskCompletions,
    taskDeletionOutbox,
    taskBackgrounds,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_recurrence_exceptions', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_completions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_backgrounds', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TaskListsTableCreateCompanionBuilder =
    TaskListsCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });
typedef $$TaskListsTableUpdateCompanionBuilder =
    TaskListsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });

final class $$TaskListsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskListsTable, TaskList> {
  $$TaskListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'task_lists__id__tasks__list_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskListsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskListsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskListsTable,
          TaskList,
          $$TaskListsTableFilterComposer,
          $$TaskListsTableOrderingComposer,
          $$TaskListsTableAnnotationComposer,
          $$TaskListsTableCreateCompanionBuilder,
          $$TaskListsTableUpdateCompanionBuilder,
          (TaskList, $$TaskListsTableReferences),
          TaskList,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$TaskListsTableTableManager(_$AppDatabase db, $TaskListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskListsCompanion(
                id: id,
                userId: userId,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskListsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<TaskList, $TaskListsTable, Task>(
                      currentTable: table,
                      referencedTable: $$TaskListsTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TaskListsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TaskListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskListsTable,
      TaskList,
      $$TaskListsTableFilterComposer,
      $$TaskListsTableOrderingComposer,
      $$TaskListsTableAnnotationComposer,
      $$TaskListsTableCreateCompanionBuilder,
      $$TaskListsTableUpdateCompanionBuilder,
      (TaskList, $$TaskListsTableReferences),
      TaskList,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String listId,
      required String title,
      Value<String?> description,
      Value<int> priority,
      Value<DateTime?> dueDate,
      Value<bool> isAllDay,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> siyuanBlockId,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> creationSource,
      Value<String?> tag,
      Value<String?> recurrenceRule,
      Value<DateTime?> recurrenceEnd,
      Value<int?> recurrenceCount,
      Value<int?> durationMin,
      Value<String?> recurrenceSeriesId,
      Value<bool> syncPending,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String> title,
      Value<String?> description,
      Value<int> priority,
      Value<DateTime?> dueDate,
      Value<bool> isAllDay,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> siyuanBlockId,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> creationSource,
      Value<String?> tag,
      Value<String?> recurrenceRule,
      Value<DateTime?> recurrenceEnd,
      Value<int?> recurrenceCount,
      Value<int?> durationMin,
      Value<String?> recurrenceSeriesId,
      Value<bool> syncPending,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TaskListsTable _listIdTable(_$AppDatabase db) =>
      db.taskLists.createAlias('tasks__list_id__task_lists__id');

  $$TaskListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$TaskListsTableTableManager(
      $_db,
      $_db.taskLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TaskRecurrenceExceptionsTable,
    List<TaskRecurrenceException>
  >
  _taskRecurrenceExceptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskRecurrenceExceptions,
        aliasName: 'tasks__id__task_recurrence_exceptions__task_id',
      );

  $$TaskRecurrenceExceptionsTableProcessedTableManager
  get taskRecurrenceExceptionsRefs {
    final manager = $$TaskRecurrenceExceptionsTableTableManager(
      $_db,
      $_db.taskRecurrenceExceptions,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskRecurrenceExceptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskCompletionsTable, List<TaskCompletion>>
  _taskCompletionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskCompletions,
    aliasName: 'tasks__id__task_completions__task_id',
  );

  $$TaskCompletionsTableProcessedTableManager get taskCompletionsRefs {
    final manager = $$TaskCompletionsTableTableManager(
      $_db,
      $_db.taskCompletions,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskBackgroundsTable, List<TaskBackground>>
  _taskBackgroundsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskBackgrounds,
    aliasName: 'tasks__id__task_backgrounds__task_id',
  );

  $$TaskBackgroundsTableProcessedTableManager get taskBackgroundsRefs {
    final manager = $$TaskBackgroundsTableTableManager(
      $_db,
      $_db.taskBackgrounds,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskBackgroundsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siyuanBlockId => $composableBuilder(
    column: $table.siyuanBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creationSource => $composableBuilder(
    column: $table.creationSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recurrenceEnd => $composableBuilder(
    column: $table.recurrenceEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceCount => $composableBuilder(
    column: $table.recurrenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceSeriesId => $composableBuilder(
    column: $table.recurrenceSeriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskListsTableFilterComposer get listId {
    final $$TaskListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.taskLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskListsTableFilterComposer(
            $db: $db,
            $table: $db.taskLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskRecurrenceExceptionsRefs(
    Expression<bool> Function($$TaskRecurrenceExceptionsTableFilterComposer f)
    f,
  ) {
    final $$TaskRecurrenceExceptionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceExceptions,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceExceptionsTableFilterComposer(
                $db: $db,
                $table: $db.taskRecurrenceExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> taskCompletionsRefs(
    Expression<bool> Function($$TaskCompletionsTableFilterComposer f) f,
  ) {
    final $$TaskCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskCompletions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.taskCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskBackgroundsRefs(
    Expression<bool> Function($$TaskBackgroundsTableFilterComposer f) f,
  ) {
    final $$TaskBackgroundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskBackgrounds,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskBackgroundsTableFilterComposer(
            $db: $db,
            $table: $db.taskBackgrounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siyuanBlockId => $composableBuilder(
    column: $table.siyuanBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creationSource => $composableBuilder(
    column: $table.creationSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recurrenceEnd => $composableBuilder(
    column: $table.recurrenceEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceCount => $composableBuilder(
    column: $table.recurrenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceSeriesId => $composableBuilder(
    column: $table.recurrenceSeriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskListsTableOrderingComposer get listId {
    final $$TaskListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.taskLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskListsTableOrderingComposer(
            $db: $db,
            $table: $db.taskLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siyuanBlockId => $composableBuilder(
    column: $table.siyuanBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get creationSource => $composableBuilder(
    column: $table.creationSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recurrenceEnd => $composableBuilder(
    column: $table.recurrenceEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceCount => $composableBuilder(
    column: $table.recurrenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceSeriesId => $composableBuilder(
    column: $table.recurrenceSeriesId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  $$TaskListsTableAnnotationComposer get listId {
    final $$TaskListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.taskLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskListsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskRecurrenceExceptionsRefs<T extends Object>(
    Expression<T> Function($$TaskRecurrenceExceptionsTableAnnotationComposer a)
    f,
  ) {
    final $$TaskRecurrenceExceptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceExceptions,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceExceptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskRecurrenceExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskCompletionsRefs<T extends Object>(
    Expression<T> Function($$TaskCompletionsTableAnnotationComposer a) f,
  ) {
    final $$TaskCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskCompletions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskBackgroundsRefs<T extends Object>(
    Expression<T> Function($$TaskBackgroundsTableAnnotationComposer a) f,
  ) {
    final $$TaskBackgroundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskBackgrounds,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskBackgroundsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskBackgrounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool listId,
            bool taskRecurrenceExceptionsRefs,
            bool taskCompletionsRefs,
            bool taskBackgroundsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> siyuanBlockId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> creationSource = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<DateTime?> recurrenceEnd = const Value.absent(),
                Value<int?> recurrenceCount = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<String?> recurrenceSeriesId = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                listId: listId,
                title: title,
                description: description,
                priority: priority,
                dueDate: dueDate,
                isAllDay: isAllDay,
                isCompleted: isCompleted,
                completedAt: completedAt,
                siyuanBlockId: siyuanBlockId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                creationSource: creationSource,
                tag: tag,
                recurrenceRule: recurrenceRule,
                recurrenceEnd: recurrenceEnd,
                recurrenceCount: recurrenceCount,
                durationMin: durationMin,
                recurrenceSeriesId: recurrenceSeriesId,
                syncPending: syncPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> siyuanBlockId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> creationSource = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<DateTime?> recurrenceEnd = const Value.absent(),
                Value<int?> recurrenceCount = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<String?> recurrenceSeriesId = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                listId: listId,
                title: title,
                description: description,
                priority: priority,
                dueDate: dueDate,
                isAllDay: isAllDay,
                isCompleted: isCompleted,
                completedAt: completedAt,
                siyuanBlockId: siyuanBlockId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                creationSource: creationSource,
                tag: tag,
                recurrenceRule: recurrenceRule,
                recurrenceEnd: recurrenceEnd,
                recurrenceCount: recurrenceCount,
                durationMin: durationMin,
                recurrenceSeriesId: recurrenceSeriesId,
                syncPending: syncPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                listId = false,
                taskRecurrenceExceptionsRefs = false,
                taskCompletionsRefs = false,
                taskBackgroundsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskRecurrenceExceptionsRefs)
                      db.taskRecurrenceExceptions,
                    if (taskCompletionsRefs) db.taskCompletions,
                    if (taskBackgroundsRefs) db.taskBackgrounds,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (listId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.listId,
                                    referencedTable: $$TasksTableReferences
                                        ._listIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._listIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskRecurrenceExceptionsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskRecurrenceException
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskRecurrenceExceptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRecurrenceExceptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskCompletionsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskCompletion
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskCompletionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskBackgroundsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskBackground
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskBackgroundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskBackgroundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool listId,
        bool taskRecurrenceExceptionsRefs,
        bool taskCompletionsRefs,
        bool taskBackgroundsRefs,
      })
    >;
typedef $$TaskRecurrenceExceptionsTableCreateCompanionBuilder =
    TaskRecurrenceExceptionsCompanion Function({
      required String taskId,
      required DateTime exceptionDate,
      Value<DateTime?> overrideDue,
      Value<String?> overrideTitle,
      Value<bool> isCancelled,
      Value<bool> syncPending,
      Value<int> rowid,
    });
typedef $$TaskRecurrenceExceptionsTableUpdateCompanionBuilder =
    TaskRecurrenceExceptionsCompanion Function({
      Value<String> taskId,
      Value<DateTime> exceptionDate,
      Value<DateTime?> overrideDue,
      Value<String?> overrideTitle,
      Value<bool> isCancelled,
      Value<bool> syncPending,
      Value<int> rowid,
    });

final class $$TaskRecurrenceExceptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskRecurrenceExceptionsTable,
          TaskRecurrenceException
        > {
  $$TaskRecurrenceExceptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_recurrence_exceptions__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRecurrenceExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionsTable> {
  $$TaskRecurrenceExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get exceptionDate => $composableBuilder(
    column: $table.exceptionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get overrideDue => $composableBuilder(
    column: $table.overrideDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionsTable> {
  $$TaskRecurrenceExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get exceptionDate => $composableBuilder(
    column: $table.exceptionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get overrideDue => $composableBuilder(
    column: $table.overrideDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionsTable> {
  $$TaskRecurrenceExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get exceptionDate => $composableBuilder(
    column: $table.exceptionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get overrideDue => $composableBuilder(
    column: $table.overrideDue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRecurrenceExceptionsTable,
          TaskRecurrenceException,
          $$TaskRecurrenceExceptionsTableFilterComposer,
          $$TaskRecurrenceExceptionsTableOrderingComposer,
          $$TaskRecurrenceExceptionsTableAnnotationComposer,
          $$TaskRecurrenceExceptionsTableCreateCompanionBuilder,
          $$TaskRecurrenceExceptionsTableUpdateCompanionBuilder,
          (TaskRecurrenceException, $$TaskRecurrenceExceptionsTableReferences),
          TaskRecurrenceException,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRecurrenceExceptionsTableTableManager(
    _$AppDatabase db,
    $TaskRecurrenceExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRecurrenceExceptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskRecurrenceExceptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskRecurrenceExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> exceptionDate = const Value.absent(),
                Value<DateTime?> overrideDue = const Value.absent(),
                Value<String?> overrideTitle = const Value.absent(),
                Value<bool> isCancelled = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceExceptionsCompanion(
                taskId: taskId,
                exceptionDate: exceptionDate,
                overrideDue: overrideDue,
                overrideTitle: overrideTitle,
                isCancelled: isCancelled,
                syncPending: syncPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required DateTime exceptionDate,
                Value<DateTime?> overrideDue = const Value.absent(),
                Value<String?> overrideTitle = const Value.absent(),
                Value<bool> isCancelled = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceExceptionsCompanion.insert(
                taskId: taskId,
                exceptionDate: exceptionDate,
                overrideDue: overrideDue,
                overrideTitle: overrideTitle,
                isCancelled: isCancelled,
                syncPending: syncPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRecurrenceExceptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskRecurrenceExceptionsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskRecurrenceExceptionsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskRecurrenceExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRecurrenceExceptionsTable,
      TaskRecurrenceException,
      $$TaskRecurrenceExceptionsTableFilterComposer,
      $$TaskRecurrenceExceptionsTableOrderingComposer,
      $$TaskRecurrenceExceptionsTableAnnotationComposer,
      $$TaskRecurrenceExceptionsTableCreateCompanionBuilder,
      $$TaskRecurrenceExceptionsTableUpdateCompanionBuilder,
      (TaskRecurrenceException, $$TaskRecurrenceExceptionsTableReferences),
      TaskRecurrenceException,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskCompletionsTableCreateCompanionBuilder =
    TaskCompletionsCompanion Function({
      required String taskId,
      required DateTime occurrenceDate,
      Value<DateTime> completedAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });
typedef $$TaskCompletionsTableUpdateCompanionBuilder =
    TaskCompletionsCompanion Function({
      Value<String> taskId,
      Value<DateTime> occurrenceDate,
      Value<DateTime> completedAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });

final class $$TaskCompletionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskCompletionsTable, TaskCompletion> {
  $$TaskCompletionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_completions__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskCompletionsTable,
          TaskCompletion,
          $$TaskCompletionsTableFilterComposer,
          $$TaskCompletionsTableOrderingComposer,
          $$TaskCompletionsTableAnnotationComposer,
          $$TaskCompletionsTableCreateCompanionBuilder,
          $$TaskCompletionsTableUpdateCompanionBuilder,
          (TaskCompletion, $$TaskCompletionsTableReferences),
          TaskCompletion,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskCompletionsTableTableManager(
    _$AppDatabase db,
    $TaskCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> occurrenceDate = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskCompletionsCompanion(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                completedAt: completedAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required DateTime occurrenceDate,
                Value<DateTime> completedAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskCompletionsCompanion.insert(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                completedAt: completedAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskCompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskCompletionsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskCompletionsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskCompletionsTable,
      TaskCompletion,
      $$TaskCompletionsTableFilterComposer,
      $$TaskCompletionsTableOrderingComposer,
      $$TaskCompletionsTableAnnotationComposer,
      $$TaskCompletionsTableCreateCompanionBuilder,
      $$TaskCompletionsTableUpdateCompanionBuilder,
      (TaskCompletion, $$TaskCompletionsTableReferences),
      TaskCompletion,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskDeletionOutboxTableCreateCompanionBuilder =
    TaskDeletionOutboxCompanion Function({
      required String taskId,
      Value<DateTime> deletedAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });
typedef $$TaskDeletionOutboxTableUpdateCompanionBuilder =
    TaskDeletionOutboxCompanion Function({
      Value<String> taskId,
      Value<DateTime> deletedAt,
      Value<bool> syncPending,
      Value<int> rowid,
    });

class $$TaskDeletionOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $TaskDeletionOutboxTable> {
  $$TaskDeletionOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskDeletionOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskDeletionOutboxTable> {
  $$TaskDeletionOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskDeletionOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskDeletionOutboxTable> {
  $$TaskDeletionOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );
}

class $$TaskDeletionOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskDeletionOutboxTable,
          TaskDeletionOutboxData,
          $$TaskDeletionOutboxTableFilterComposer,
          $$TaskDeletionOutboxTableOrderingComposer,
          $$TaskDeletionOutboxTableAnnotationComposer,
          $$TaskDeletionOutboxTableCreateCompanionBuilder,
          $$TaskDeletionOutboxTableUpdateCompanionBuilder,
          (
            TaskDeletionOutboxData,
            BaseReferences<
              _$AppDatabase,
              $TaskDeletionOutboxTable,
              TaskDeletionOutboxData
            >,
          ),
          TaskDeletionOutboxData,
          PrefetchHooks Function()
        > {
  $$TaskDeletionOutboxTableTableManager(
    _$AppDatabase db,
    $TaskDeletionOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskDeletionOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskDeletionOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskDeletionOutboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskDeletionOutboxCompanion(
                taskId: taskId,
                deletedAt: deletedAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskDeletionOutboxCompanion.insert(
                taskId: taskId,
                deletedAt: deletedAt,
                syncPending: syncPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskDeletionOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskDeletionOutboxTable,
      TaskDeletionOutboxData,
      $$TaskDeletionOutboxTableFilterComposer,
      $$TaskDeletionOutboxTableOrderingComposer,
      $$TaskDeletionOutboxTableAnnotationComposer,
      $$TaskDeletionOutboxTableCreateCompanionBuilder,
      $$TaskDeletionOutboxTableUpdateCompanionBuilder,
      (
        TaskDeletionOutboxData,
        BaseReferences<
          _$AppDatabase,
          $TaskDeletionOutboxTable,
          TaskDeletionOutboxData
        >,
      ),
      TaskDeletionOutboxData,
      PrefetchHooks Function()
    >;
typedef $$TaskBackgroundsTableCreateCompanionBuilder =
    TaskBackgroundsCompanion Function({
      required String taskId,
      required String imagePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TaskBackgroundsTableUpdateCompanionBuilder =
    TaskBackgroundsCompanion Function({
      Value<String> taskId,
      Value<String> imagePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TaskBackgroundsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskBackgroundsTable, TaskBackground> {
  $$TaskBackgroundsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_backgrounds__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskBackgroundsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskBackgroundsTable> {
  $$TaskBackgroundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskBackgroundsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskBackgroundsTable> {
  $$TaskBackgroundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskBackgroundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskBackgroundsTable> {
  $$TaskBackgroundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskBackgroundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskBackgroundsTable,
          TaskBackground,
          $$TaskBackgroundsTableFilterComposer,
          $$TaskBackgroundsTableOrderingComposer,
          $$TaskBackgroundsTableAnnotationComposer,
          $$TaskBackgroundsTableCreateCompanionBuilder,
          $$TaskBackgroundsTableUpdateCompanionBuilder,
          (TaskBackground, $$TaskBackgroundsTableReferences),
          TaskBackground,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskBackgroundsTableTableManager(
    _$AppDatabase db,
    $TaskBackgroundsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskBackgroundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskBackgroundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskBackgroundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskBackgroundsCompanion(
                taskId: taskId,
                imagePath: imagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String imagePath,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskBackgroundsCompanion.insert(
                taskId: taskId,
                imagePath: imagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskBackgroundsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskBackgroundsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskBackgroundsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskBackgroundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskBackgroundsTable,
      TaskBackground,
      $$TaskBackgroundsTableFilterComposer,
      $$TaskBackgroundsTableOrderingComposer,
      $$TaskBackgroundsTableAnnotationComposer,
      $$TaskBackgroundsTableCreateCompanionBuilder,
      $$TaskBackgroundsTableUpdateCompanionBuilder,
      (TaskBackground, $$TaskBackgroundsTableReferences),
      TaskBackground,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskListsTableTableManager get taskLists =>
      $$TaskListsTableTableManager(_db, _db.taskLists);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskRecurrenceExceptionsTableTableManager get taskRecurrenceExceptions =>
      $$TaskRecurrenceExceptionsTableTableManager(
        _db,
        _db.taskRecurrenceExceptions,
      );
  $$TaskCompletionsTableTableManager get taskCompletions =>
      $$TaskCompletionsTableTableManager(_db, _db.taskCompletions);
  $$TaskDeletionOutboxTableTableManager get taskDeletionOutbox =>
      $$TaskDeletionOutboxTableTableManager(_db, _db.taskDeletionOutbox);
  $$TaskBackgroundsTableTableManager get taskBackgrounds =>
      $$TaskBackgroundsTableTableManager(_db, _db.taskBackgrounds);
}
