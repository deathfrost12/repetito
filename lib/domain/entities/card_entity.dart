import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_entity.freezed.dart';
part 'card_entity.g.dart';

@freezed
class CardEntity with _$CardEntity {
  const factory CardEntity({
    required String id,
    required String deckId,
    required String frontContent,
    required String backContent,
    String? frontImageUrl,
    String? backImageUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _CardEntity;

  factory CardEntity.fromJson(Map<String, dynamic> json) =>
      _$CardEntityFromJson(json);
} 