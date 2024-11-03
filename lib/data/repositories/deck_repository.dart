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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final response = await _client
        .from('decks')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return response.map((row) => _mapToDeckEntity(row)).toList();
  }

  Stream<List<DeckEntity>> watchDecks() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    return _client
        .from('decks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((event) {
          debugPrint('Received decks update: ${event.length} decks');
          return event.map((row) => _mapToDeckEntity(row)).toList();
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
      folderId: row['folder_id'] as String?,
      name: row['name'] as String,
      description: row['description'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
} 