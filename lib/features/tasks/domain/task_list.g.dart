// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskListImpl _$$TaskListImplFromJson(Map<String, dynamic> json) =>
    _$TaskListImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TaskListImplToJson(_$TaskListImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt.toIso8601String(),
    };
