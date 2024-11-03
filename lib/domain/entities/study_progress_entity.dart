import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/difficulty_level.dart';

part 'study_progress_entity.freezed.dart';
part 'study_progress_entity.g.dart';

@freezed
class StudyProgressEntity with _$StudyProgressEntity {
  const factory StudyProgressEntity({
    required String id,
    required String cardId,
    required String userId,
    required int repetitionCount,
    @JsonKey(name: 'last_reviewed_at') required DateTime lastReviewedAt,
    @JsonKey(name: 'next_review_at') required DateTime nextReviewAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _StudyProgressEntity;

  factory StudyProgressEntity.fromJson(Map<String, dynamic> json) =>
      _$StudyProgressEntityFromJson(json);
}

// Pomocná třída pro výpočet intervalu opakování
class SpacedRepetition {
  static DateTime calculateNextReview(
    DifficultyLevel difficulty,
    int repetitionCount,
    DateTime lastReviewedAt,
  ) {
    // Základní interval v hodinách podle obtížnosti
    final baseInterval = switch (difficulty) {
      DifficultyLevel.easy => 24 * 2.5,    // 2.5 dny
      DifficultyLevel.medium => 24,         // 1 den
      DifficultyLevel.hard => 6,            // 6 hodin
    };

    // Násobitel podle počtu opakování (exponenciální růst)
    final multiplier = (1.5 * repetitionCount).clamp(1.0, 30.0);

    // Výpočet intervalu v hodinách
    final intervalHours = (baseInterval * multiplier).round();

    // Přidání náhodné odchylky ±10% pro přirozenější rozložení
    final randomFactor = 0.9 + (DateTime.now().millisecondsSinceEpoch % 200) / 1000;
    final finalIntervalHours = (intervalHours * randomFactor).round();

    return lastReviewedAt.add(Duration(hours: finalIntervalHours));
  }
} 