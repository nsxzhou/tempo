// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskList _$TaskListFromJson(Map<String, dynamic> json) {
  return _TaskList.fromJson(json);
}

/// @nodoc
mixin _$TaskList {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get syncPending => throw _privateConstructorUsedError;

  /// Serializes this TaskList to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskListCopyWith<TaskList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskListCopyWith<$Res> {
  factory $TaskListCopyWith(TaskList value, $Res Function(TaskList) then) =
      _$TaskListCopyWithImpl<$Res, TaskList>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    int sortOrder,
    DateTime createdAt,
    bool syncPending,
  });
}

/// @nodoc
class _$TaskListCopyWithImpl<$Res, $Val extends TaskList>
    implements $TaskListCopyWith<$Res> {
  _$TaskListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? syncPending = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$TaskListImplCopyWith<$Res>
    implements $TaskListCopyWith<$Res> {
  factory _$$TaskListImplCopyWith(
    _$TaskListImpl value,
    $Res Function(_$TaskListImpl) then,
  ) = __$$TaskListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    int sortOrder,
    DateTime createdAt,
    bool syncPending,
  });
}

/// @nodoc
class __$$TaskListImplCopyWithImpl<$Res>
    extends _$TaskListCopyWithImpl<$Res, _$TaskListImpl>
    implements _$$TaskListImplCopyWith<$Res> {
  __$$TaskListImplCopyWithImpl(
    _$TaskListImpl _value,
    $Res Function(_$TaskListImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? syncPending = null,
  }) {
    return _then(
      _$TaskListImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
class _$TaskListImpl implements _TaskList {
  const _$TaskListImpl({
    required this.id,
    required this.userId,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
    this.syncPending = false,
  });

  factory _$TaskListImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskListImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool syncPending;

  @override
  String toString() {
    return 'TaskList(id: $id, userId: $userId, name: $name, sortOrder: $sortOrder, createdAt: $createdAt, syncPending: $syncPending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskListImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.syncPending, syncPending) ||
                other.syncPending == syncPending));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    sortOrder,
    createdAt,
    syncPending,
  );

  /// Create a copy of TaskList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskListImplCopyWith<_$TaskListImpl> get copyWith =>
      __$$TaskListImplCopyWithImpl<_$TaskListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskListImplToJson(this);
  }
}

abstract class _TaskList implements TaskList {
  const factory _TaskList({
    required final String id,
    required final String userId,
    required final String name,
    final int sortOrder,
    required final DateTime createdAt,
    final bool syncPending,
  }) = _$TaskListImpl;

  factory _TaskList.fromJson(Map<String, dynamic> json) =
      _$TaskListImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  int get sortOrder;
  @override
  DateTime get createdAt;
  @override
  bool get syncPending;

  /// Create a copy of TaskList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskListImplCopyWith<_$TaskListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
