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
        syncPending.isAcceptableOrUnknown(data['sync_pending']!, _syncPendingMeta),
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
      syncPending: data.syncPending.present ? data.syncPending.value : this.syncPending,
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
  int get hashCode => Object.hash(id, userId, name, sortOrder, createdAt, syncPending);
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
    isCompleted,
    completedAt,
    siyuanBlockId,
    sortOrder,
    createdAt,
    updatedAt,
    creationSource,
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
  final bool isCompleted;
  final DateTime? completedAt;
  final String? siyuanBlockId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 创建来源: 'text' | 'siyuan' | 'voice' | 'ai'
  final String creationSource;
  final bool syncPending;
  const Task({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    required this.isCompleted,
    this.completedAt,
    this.siyuanBlockId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.creationSource,
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
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      siyuanBlockId: serializer.fromJson<String?>(json['siyuanBlockId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      creationSource: serializer.fromJson<String>(json['creationSource']),
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
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'siyuanBlockId': serializer.toJson<String?>(siyuanBlockId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'creationSource': serializer.toJson<String>(creationSource),
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
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> siyuanBlockId = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creationSource,
    bool? syncPending,
  }) => Task(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    siyuanBlockId: siyuanBlockId.present
        ? siyuanBlockId.value
        : this.siyuanBlockId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    creationSource: creationSource ?? this.creationSource,
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
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('siyuanBlockId: $siyuanBlockId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('creationSource: $creationSource, ')
          ..write('syncPending: $syncPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    title,
    description,
    priority,
    dueDate,
    isCompleted,
    completedAt,
    siyuanBlockId,
    sortOrder,
    createdAt,
    updatedAt,
    creationSource,
    syncPending,
  );
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
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.siyuanBlockId == this.siyuanBlockId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.creationSource == this.creationSource &&
          other.syncPending == this.syncPending);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<DateTime?> dueDate;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String?> siyuanBlockId;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> creationSource;
  final Value<bool> syncPending;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.siyuanBlockId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.creationSource = const Value.absent(),
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
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.siyuanBlockId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.creationSource = const Value.absent(),
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
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? siyuanBlockId,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? creationSource,
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
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (siyuanBlockId != null) 'siyuan_block_id': siyuanBlockId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (creationSource != null) 'creation_source': creationSource,
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
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<String?>? siyuanBlockId,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? creationSource,
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
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      siyuanBlockId: siyuanBlockId ?? this.siyuanBlockId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creationSource: creationSource ?? this.creationSource,
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
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('siyuanBlockId: $siyuanBlockId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('creationSource: $creationSource, ')
          ..write('syncPending: $syncPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TaskListsTable taskLists = $TaskListsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [taskLists, tasks];
}
