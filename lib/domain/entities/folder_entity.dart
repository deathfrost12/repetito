import 'package:json_annotation/json_annotation.dart';

part 'folder_entity.g.dart';

@JsonSerializable()
class FolderEntity {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  @JsonKey(defaultValue: 'blue')
  final String color;
  @JsonKey(defaultValue: 'folder')
  final String icon;
  final String? description;
  @JsonKey(name: 'created_at', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime updatedAt;

  const FolderEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderEntity.fromJson(Map<String, dynamic> json) => _$FolderEntityFromJson(json);

  Map<String, dynamic> toJson() => _$FolderEntityToJson(this);

  static DateTime _dateFromJson(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  static String _dateToJson(DateTime date) => date.toIso8601String();
} 