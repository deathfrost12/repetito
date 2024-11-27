import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/study_statistics_entity.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../data/repositories/study_statistics_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;

part 'study_statistics_provider.g.dart';

@riverpod
Future<StudyStatisticsEntity?> studyStatistics(StudyStatisticsRef ref, String deckId) async {
  debugPrint('Načítám statistiky pro balíček: $deckId');
  final repository = ref.watch(studyStatisticsRepositoryProvider);
  final statistics = await repository.getStatistics(deckId);
  debugPrint('Načtené statistiky: $statistics');
  return statistics;
}

@riverpod
class StudyStatisticsNotifier extends _$StudyStatisticsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateStatistics({
    required String deckId,
    required DifficultyLevel difficulty,
    required int studyTimeSeconds,
  }) async {
    if (state.isLoading) {
      debugPrint('Již probíhá aktualizace, přeskakuji...');
      return;
    }
    
    debugPrint('Aktualizuji statistiky pro balíček: $deckId');
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(studyStatisticsRepositoryProvider);
      await repository.updateStatistics(
        deckId: deckId,
        difficulty: difficulty,
        studyTimeSeconds: studyTimeSeconds,
      );
      debugPrint('Statistiky úspěšně aktualizovány');
      
      // Invalidujeme provider pro statistiky
      ref.invalidate(studyStatisticsProvider(deckId));
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Chyba při aktualizaci: $error');
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

// Provider pro celkové statistiky uživatele
@riverpod
Future<Map<String, StudyStatisticsEntity>> userStatistics(UserStatisticsRef ref) async {
  debugPrint('Načítám statistiky uživatele');
  final repository = ref.watch(studyStatisticsRepositoryProvider);
  final statistics = await repository.getUserStatistics();
  debugPrint('Načtené statistiky uživatele: $statistics');
  return statistics;
} 