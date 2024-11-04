import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/study_statistics_entity.dart';
import '../../domain/enums/difficulty_level.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

part 'study_statistics_repository.g.dart';

@riverpod
StudyStatisticsRepository studyStatisticsRepository(StudyStatisticsRepositoryRef ref) {
  return StudyStatisticsRepository(Supabase.instance.client);
}

class StudyStatisticsRepository {
  final SupabaseClient _client;

  StudyStatisticsRepository(this._client);

  Future<void> updateStatistics({
    required String deckId,
    required DifficultyLevel difficulty,
    required int studyTimeSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final now = DateTime.now();

    try {
      // Nejprve získáme existující statistiky
      final existingStats = await _client
          .from('study_statistics')
          .select()
          .eq('deck_id', deckId)
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('Existující statistiky: $existingStats');

      if (existingStats != null) {
        // Aktualizujeme existující záznam
        final updateData = {
          'total_cards_studied': (existingStats['total_cards_studied'] as int) + 1,
          'total_study_time_seconds': (existingStats['total_study_time_seconds'] as int) + studyTimeSeconds,
          'easy_count': (existingStats['easy_count'] as int) + (difficulty == DifficultyLevel.easy ? 1 : 0),
          'medium_count': (existingStats['medium_count'] as int) + (difficulty == DifficultyLevel.medium ? 1 : 0),
          'hard_count': (existingStats['hard_count'] as int) + (difficulty == DifficultyLevel.hard ? 1 : 0),
          'last_study_date': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        await _client
            .from('study_statistics')
            .update(updateData)
            .eq('id', existingStats['id']);
            
        debugPrint('Statistiky úspěšně aktualizovány');
      } else {
        // Vytvoříme nový záznam
        final newData = {
          'id': const Uuid().v4(),
          'deck_id': deckId,
          'user_id': userId,
          'total_cards_studied': 1,
          'total_study_time_seconds': studyTimeSeconds,
          'easy_count': difficulty == DifficultyLevel.easy ? 1 : 0,
          'medium_count': difficulty == DifficultyLevel.medium ? 1 : 0,
          'hard_count': difficulty == DifficultyLevel.hard ? 1 : 0,
          'streak_days': 1,
          'last_study_date': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        await _client
            .from('study_statistics')
            .insert(newData);
            
        debugPrint('Nové statistiky úspěšně vytvořeny');
      }
    } catch (e, stack) {
      debugPrint('Chyba při aktualizaci statistik: $e\n$stack');
      rethrow;
    }
  }

  Future<StudyStatisticsEntity?> getStatistics(String deckId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    try {
      debugPrint('Načítám statistiky pro balíček $deckId a uživatele $userId');
      
      final response = await _client
          .from('study_statistics')
          .select()
          .eq('deck_id', deckId)
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('Odpověď ze serveru (getStatistics): $response');

      if (response == null) {
        debugPrint('Žádné statistiky nenalezeny');
        return null;
      }

      // Zajistíme, že všechny hodnoty jsou správného typu
      final data = {
        'id': response['id']?.toString() ?? '',
        'user_id': response['user_id']?.toString() ?? '',
        'deck_id': response['deck_id']?.toString() ?? '',
        'total_cards_studied': (response['total_cards_studied'] as num?)?.toInt() ?? 0,
        'total_study_time_seconds': (response['total_study_time_seconds'] as num?)?.toInt() ?? 0,
        'easy_count': (response['easy_count'] as num?)?.toInt() ?? 0,
        'medium_count': (response['medium_count'] as num?)?.toInt() ?? 0,
        'hard_count': (response['hard_count'] as num?)?.toInt() ?? 0,
        'streak_days': (response['streak_days'] as num?)?.toInt() ?? 0,
        'last_study_date': DateTime.parse(response['last_study_date']?.toString() ?? DateTime.now().toIso8601String()),
        'created_at': DateTime.parse(response['created_at']?.toString() ?? DateTime.now().toIso8601String()),
        'updated_at': DateTime.parse(response['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      };

      debugPrint('Zpracovaná data: $data');
      return StudyStatisticsEntity.fromJson(data);
    } catch (e, stack) {
      debugPrint('Chyba při načítání statistik: $e\n$stack');
      return null;
    }
  }

  Future<Map<String, StudyStatisticsEntity>> getUserStatistics() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    try {
      debugPrint('Načítám statistiky pro uživatele: $userId');
      
      final response = await _client
          .from('study_statistics')
          .select()
          .eq('user_id', userId);

      debugPrint('Odpověď ze serveru (getUserStatistics): $response');

      final result = <String, StudyStatisticsEntity>{};
      
      for (final row in response) {
        try {
          final deckId = row['deck_id']?.toString();
          if (deckId == null) continue;

          // Zajistíme, že všechny hodnoty jsou správného typu
          final data = {
            'id': row['id']?.toString() ?? '',
            'user_id': row['user_id']?.toString() ?? '',
            'deck_id': deckId,
            'total_cards_studied': (row['total_cards_studied'] as num?)?.toInt() ?? 0,
            'total_study_time_seconds': (row['total_study_time_seconds'] as num?)?.toInt() ?? 0,
            'easy_count': (row['easy_count'] as num?)?.toInt() ?? 0,
            'medium_count': (row['medium_count'] as num?)?.toInt() ?? 0,
            'hard_count': (row['hard_count'] as num?)?.toInt() ?? 0,
            'streak_days': (row['streak_days'] as num?)?.toInt() ?? 0,
            'last_study_date': DateTime.parse(row['last_study_date']?.toString() ?? DateTime.now().toIso8601String()),
            'created_at': DateTime.parse(row['created_at']?.toString() ?? DateTime.now().toIso8601String()),
            'updated_at': DateTime.parse(row['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
          };

          debugPrint('Zpracovaná data pro balíček $deckId: $data');
          result[deckId] = StudyStatisticsEntity.fromJson(data);
        } catch (e, stack) {
          debugPrint('Chyba při zpracování řádku: $e\n$stack');
          continue;
        }
      }

      debugPrint('Zpracované statistiky: $result');
      return result;
    } catch (e, stack) {
      debugPrint('Chyba při načítání statistik uživatele: $e\n$stack');
      return {};
    }
  }
} 