import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../domain/entities/card_entity.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../data/repositories/study_progress_repository.dart';
import '../../data/repositories/card_repository.dart';

part 'study_progress_provider.g.dart';

@riverpod
class StudyProgress extends _$StudyProgress {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateProgress({
    required String cardId,
    required DifficultyLevel difficulty,
  }) async {
    if (state.isLoading) {
      debugPrint('Již probíhá aktualizace, přeskakuji...');
      return;
    }
    
    debugPrint('Začínám aktualizaci pro kartičku $cardId s obtížností ${difficulty.name}');
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(studyProgressRepositoryProvider);
      await repository.updateProgress(
        cardId: cardId,
        difficulty: difficulty,
      );
      debugPrint('Aktualizace úspěšně dokončena');
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Chyba při aktualizaci: $error');
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

@riverpod
Future<List<CardEntity>> dueCards(DueCardsRef ref, String deckId) async {
  final studyProgressRepository = ref.watch(studyProgressRepositoryProvider);
  final cardRepository = ref.watch(cardRepositoryProvider);
  
  final cardIds = await studyProgressRepository.getDueCardIds(deckId);
  return cardRepository.getCardsByIds(cardIds);
} 