import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_entity.freezed.dart';
part 'deck_entity.g.dart';

@freezed
class DeckEntity with _$DeckEntity {
  const factory DeckEntity({
    required String id,
    required String userId,
    required String name,
    String? description,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _DeckEntity;

  factory DeckEntity.fromJson(Map<String, dynamic> json) =>
      _$DeckEntityFromJson(json);
} 