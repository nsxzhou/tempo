// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  String get listId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  TaskPriority get priority => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  bool get isAllDay => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String? get siyuanBlockId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String get creationSource => throw _privateConstructorUsedError;
  String? get tag => throw _privateConstructorUsedError;
  bool get syncPending => throw _privateConstructorUsedError;

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call({
    String id,
    String listId,
    String title,
    String? description,
    TaskPriority priority,
    DateTime? dueDate,
    bool isAllDay,
    bool isCompleted,
    DateTime? completedAt,
    String? siyuanBlockId,
    int sortOrder,
    DateTime createdAt,
    DateTime updatedAt,
    String creationSource,
    String? tag,
    bool syncPending,
  });
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listId = null,
    Object? title = null,
    Object? description = freezed,
    Object? priority = null,
    Object? dueDate = freezed,
    Object? isAllDay = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? siyuanBlockId = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? creationSource = null,
    Object? tag = freezed,
    Object? syncPending = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            listId: null == listId
                ? _value.listId
                : listId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as TaskPriority,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isAllDay: null == isAllDay
                ? _value.isAllDay
                : isAllDay // ignore: cast_nullable_to_non_nullable
                      as bool,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            siyuanBlockId: freezed == siyuanBlockId
                ? _value.siyuanBlockId
                : siyuanBlockId // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            creationSource: null == creationSource
                ? _value.creationSource
                : creationSource // ignore: cast_nullable_to_non_nullable
                      as String,
            tag: freezed == tag
                ? _value.tag
                : tag // ignore: cast_nullable_to_non_nullable
                      as String?,
            syncPending: null == syncPending
                ? _value.syncPending
                : syncPending // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
    _$TaskImpl value,
    $Res Function(_$TaskImpl) then,
  ) = __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String listId,
    String title,
    String? description,
    TaskPriority priority,
    DateTime? dueDate,
    bool isAllDay,
    bool isCompleted,
    DateTime? completedAt,
    String? siyuanBlockId,
    int sortOrder,
    DateTime createdAt,
    DateTime updatedAt,
    String creationSource,
    String? tag,
    bool syncPending,
  });
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
    : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listId = null,
    Object? title = null,
    Object? description = freezed,
    Object? priority = null,
    Object? dueDate = freezed,
    Object? isAllDay = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? siyuanBlockId = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? creationSource = null,
    Object? tag = freezed,
    Object? syncPending = null,
  }) {
    return _then(
      _$TaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        listId: null == listId
            ? _value.listId
            : listId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as TaskPriority,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isAllDay: null == isAllDay
            ? _value.isAllDay
            : isAllDay // ignore: cast_nullable_to_non_nullable
                  as bool,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        siyuanBlockId: freezed == siyuanBlockId
            ? _value.siyuanBlockId
            : siyuanBlockId // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        creationSource: null == creationSource
            ? _value.creationSource
            : creationSource // ignore: cast_nullable_to_non_nullable
                  as String,
        tag: freezed == tag
            ? _value.tag
            : tag // ignore: cast_nullable_to_non_nullable
                  as String?,
        syncPending: null == syncPending
            ? _value.syncPending
            : syncPending // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl implements _Task {
  const _$TaskImpl({
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
    this.syncPending = false,
  });

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  @override
  final String listId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final TaskPriority priority;
  @override
  final DateTime? dueDate;
  @override
  @JsonKey()
  final bool isAllDay;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? completedAt;
  @override
  final String? siyuanBlockId;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final String creationSource;
  @override
  final String? tag;
  @override
  @JsonKey()
  final bool syncPending;

  @override
  String toString() {
    return 'Task(id: $id, listId: $listId, title: $title, description: $description, priority: $priority, dueDate: $dueDate, isAllDay: $isAllDay, isCompleted: $isCompleted, completedAt: $completedAt, siyuanBlockId: $siyuanBlockId, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt, creationSource: $creationSource, tag: $tag, syncPending: $syncPending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.listId, listId) || other.listId == listId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.isAllDay, isAllDay) ||
                other.isAllDay == isAllDay) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.siyuanBlockId, siyuanBlockId) ||
                other.siyuanBlockId == siyuanBlockId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.creationSource, creationSource) ||
                other.creationSource == creationSource) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.syncPending, syncPending) ||
                other.syncPending == syncPending));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
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
    syncPending,
  );

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(this);
  }
}

abstract class _Task implements Task {
  const factory _Task({
    required final String id,
    required final String listId,
    required final String title,
    final String? description,
    final TaskPriority priority,
    final DateTime? dueDate,
    final bool isAllDay,
    final bool isCompleted,
    final DateTime? completedAt,
    final String? siyuanBlockId,
    final int sortOrder,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String creationSource,
    final String? tag,
    final bool syncPending,
  }) = _$TaskImpl;

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id;
  @override
  String get listId;
  @override
  String get title;
  @override
  String? get description;
  @override
  TaskPriority get priority;
  @override
  DateTime? get dueDate;
  @override
  bool get isAllDay;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedAt;
  @override
  String? get siyuanBlockId;
  @override
  int get sortOrder;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String get creationSource;
  @override
  String? get tag;
  @override
  bool get syncPending;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
