import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/study_progress_entity.dart';
import '../../domain/enums/difficulty_level.dart';
import 'package:flutter/foundation.dart' show debugPrint;

part 'study_progress_repository.g.dart';

@riverpod
StudyProgressRepository studyProgressRepository(StudyProgressRepositoryRef ref) {
  return StudyProgressRepository(Supabase.instance.client);
}

class StudyProgressRepository {
  final SupabaseClient _client;

  StudyProgressRepository(this._client);

  Future<StudyProgressEntity> updateProgress({
    required String cardId,
    required DifficultyLevel difficulty,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final now = DateTime.now();

    try {
      // Najít existující záznam nebo vytvořit nový
      final existingProgress = await _client
          .from('study_progress')
          .select()
          .eq('card_id', cardId)
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('Existující progress: $existingProgress');

      final repetitionCount = (existingProgress?['repetition_count'] as int? ?? 0) + 1;
      final nextReviewAt = SpacedRepetition.calculateNextReview(
        difficulty,
        repetitionCount,
        now,
      );

      final data = {
        'card_id': cardId,
        'user_id': userId,
        'repetition_count': repetitionCount,
        'last_reviewed_at': now.toIso8601String(),
        'next_review_at': nextReviewAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (existingProgress != null) {
        data['id'] = existingProgress['id'] as String;
      } else {
        data['created_at'] = now.toIso8601String();
      }

      debugPrint('Odesílaná data: $data');

      final response = await _client
          .from('study_progress')
          .upsert(data)
          .select()
          .single();

      debugPrint('Odpověď ze serveru: $response');

      return StudyProgressEntity.fromJson(response);
    } catch (e, stack) {
      debugPrint('Chyba při aktualizaci progressu: $e\n$stack');
      rethrow;
    }
  }

  Future<List<String>> getDueCardIds(String deckId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    // 1. Nejprve získáme všechny kartičky z balíčku
    final allCards = await _client
        .from('cards')
        .select('id')
        .eq('deck_id', deckId);

    final allCardIds = allCards.map<String>((row) => row['id'] as String).toList();

    if (allCardIds.isEmpty) return [];

    // 2. Pak získáme všechny záznamy o studiu pro tyto kartičky
    final now = DateTime.now().toIso8601String();
    final progress = await _client
        .from('study_progress')
        .select('card_id, next_review_at')
        .eq('user_id', userId)
        .inFilter('card_id', allCardIds);

    // 3. Vytvoříme mapu pro rychlé vyhledávání
    final progressMap = {
      for (var row in progress)
        row['card_id'] as String: DateTime.parse(row['next_review_at'] as String)
    };

    // 4. Vrátíme ID kartiček, které:
    // - Nemají záznam o studiu NEBO
    // - Mají čas příštího opakování v minulosti
    final now2 = DateTime.now();
    return allCardIds.where((cardId) {
      final nextReview = progressMap[cardId];
      return nextReview == null || nextReview.isBefore(now2);
    }).toList();
  }
} 