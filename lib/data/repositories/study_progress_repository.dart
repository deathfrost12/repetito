import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/study_progress_entity.dart';
import '../../domain/enums/difficulty_level.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

part 'study_progress_repository.g.dart';

@riverpod
StudyProgressRepository studyProgressRepository(StudyProgressRepositoryRef ref) {
  return StudyProgressRepository(Supabase.instance.client);
}

class StudyProgressRepository {
  final SupabaseClient _client;

  StudyProgressRepository(this._client);

  Future<void> updateProgress({
    required String cardId,
    required DifficultyLevel difficulty,
    required int studyTimeSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final now = DateTime.now();
    final nextReviewAt = SpacedRepetition.calculateNextReview(
      difficulty,
      1,
      now,
    );

    try {
      debugPrint('Ukládám pokrok pro kartičku: $cardId');
      
      // Vždy vygenerujeme nové ID
      final id = const Uuid().v4();
      
      // Jednoduchý insert bez složité logiky
      await _client
          .from('study_progress')
          .insert({
            'id': id,  // Přidáno ID
            'card_id': cardId,
            'user_id': userId,
            'repetition_count': 1,
            'last_reviewed_at': now.toIso8601String(),
            'next_review_at': nextReviewAt.toIso8601String(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });

      debugPrint('Pokrok úspěšně uložen');
    } catch (e, stack) {
      debugPrint('Chyba při ukládání pokroku: $e\n$stack');
      rethrow;
    }
  }

  Future<List<String>> getDueCardIds(String deckId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    // Získáme všechny kartičky z balíčku
    final allCards = await _client
        .from('cards')
        .select('id')
        .eq('deck_id', deckId);

    return allCards.map<String>((row) => row['id'] as String).toList();
  }
} 