import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/deck_entity.dart';
import 'package:flutter/foundation.dart' show debugPrint;

part 'deck_repository.g.dart';

@riverpod
DeckRepository deckRepository(DeckRepositoryRef ref) {
  return DeckRepository(Supabase.instance.client);
}

class DeckRepository {
  final SupabaseClient _client;

  DeckRepository(this._client);

  Future<DeckEntity> createDeck({
    required String name,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final now = DateTime.now().toIso8601String();
    final response = await _client.from('decks').insert({
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': now,
      'updated_at': now,
    }).select().single();

    return _mapToDeckEntity(response);
  }

  Future<List<DeckEntity>> getDecks() async {
    debugPrint('Getting decks from repository');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('User is not logged in');
      return [];
    }

    try {
      debugPrint('Executing SQL query: SELECT * FROM decks WHERE user_id = $userId');
      final response = await _client
          .from('decks')
          .select()
          .eq('user_id', userId);
      
      debugPrint('Got response from database: $response');
      debugPrint('Got ${response.length} decks from database');
      
      final decks = response.map((row) {
        debugPrint('Mapping deck row: $row');
        return _mapToDeckEntity(row);
      }).toList();
      
      debugPrint('Mapped ${decks.length} decks');
      return decks;
    } catch (e, stack) {
      debugPrint('Error getting decks: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<DeckEntity>> watchDecks() {
    debugPrint('Starting deck watch stream in repository');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('User is not logged in, returning empty stream');
      return Stream.value([]);
    }

    debugPrint('Setting up Supabase stream for decks table with user_id = $userId');
    return _client
        .from('decks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((response) {
          debugPrint('Got deck update from stream: ${response.length} decks');
          debugPrint('Raw response data: $response');
          final decks = response.map((row) {
            debugPrint('Mapping deck row: $row');
            return _mapToDeckEntity(row);
          }).toList();
          debugPrint('Mapped ${decks.length} decks to entities');
          return decks;
        });
  }

  Future<void> deleteDeck(String deckId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    await _client
        .from('decks')
        .delete()
        .eq('id', deckId)
        .eq('user_id', userId);
  }

  Future<DeckEntity> updateDeck({
    required String deckId,
    required String name,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final response = await _client
        .from('decks')
        .update({
          'name': name,
          'description': description,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deckId)
        .eq('user_id', userId)
        .select()
        .single();

    return _mapToDeckEntity(response);
  }

  Future<DeckEntity> getDeck(String deckId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final response = await _client
        .from('decks')
        .select()
        .eq('id', deckId)
        .eq('user_id', userId)
        .single();

    return _mapToDeckEntity(response);
  }

  // Pomocná metoda pro mapování dat z Supabase na DeckEntity
  DeckEntity _mapToDeckEntity(Map<String, dynamic> row) {
    return DeckEntity(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
} 