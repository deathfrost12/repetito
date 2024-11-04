import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_statistics_entity.freezed.dart';
part 'study_statistics_entity.g.dart';

DateTime _dateTimeFromJson(dynamic json) {
  if (json is DateTime) return json;
  if (json is String) return DateTime.parse(json);
  return DateTime.now();
}

String _dateTimeToJson(DateTime date) => date.toIso8601String();

@freezed
class StudyStatisticsEntity with _$StudyStatisticsEntity {
  const StudyStatisticsEntity._();

  const factory StudyStatisticsEntity({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String userId,
    @JsonKey(defaultValue: '') required String deckId,
    @JsonKey(name: 'total_cards_studied', defaultValue: 0) required int totalCardsStudied,
    @JsonKey(name: 'total_study_time_seconds', defaultValue: 0) required int totalStudyTimeSeconds,
    @JsonKey(name: 'easy_count', defaultValue: 0) required int easyCount,
    @JsonKey(name: 'medium_count', defaultValue: 0) required int mediumCount,
    @JsonKey(name: 'hard_count', defaultValue: 0) required int hardCount,
    @JsonKey(name: 'streak_days', defaultValue: 0) required int streakDays,
    @JsonKey(
      name: 'last_study_date',
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    ) required DateTime lastStudyDate,
    @JsonKey(
      name: 'created_at',
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    ) required DateTime createdAt,
    @JsonKey(
      name: 'updated_at',
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    ) required DateTime updatedAt,
  }) = _StudyStatisticsEntity;

  factory StudyStatisticsEntity.fromJson(Map<String, dynamic> json) =>
      _$StudyStatisticsEntityFromJson(json);

  // Pomocné gettery pro výpočty
  double get averageDifficulty {
    final total = easyCount + mediumCount + hardCount;
    if (total == 0) return 0;
    return (easyCount * 1 + mediumCount * 2 + hardCount * 3) / total;
  }

  double get masteryPercentage {
    final total = easyCount + mediumCount + hardCount;
    if (total == 0) return 0;
    return (easyCount / total) * 100;
  }

  String get formattedStudyTime {
    final hours = totalStudyTimeSeconds ~/ 3600;
    final minutes = (totalStudyTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }
} 