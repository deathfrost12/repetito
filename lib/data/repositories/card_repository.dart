import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/card_entity.dart';

part 'card_repository.g.dart';

@riverpod
CardRepository cardRepository(CardRepositoryRef ref) {
  return CardRepository(Supabase.instance.client);
}

class CardRepository {
  final SupabaseClient _client;

  CardRepository(this._client);

  Future<CardEntity> createCard({
    required String deckId,
    required String frontContent,
    required String backContent,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    final now = DateTime.now().toIso8601String();
    final response = await _client.from('cards').insert({
      'deck_id': deckId,
      'front_content': frontContent,
      'back_content': backContent,
      'created_at': now,
      'updated_at': now,
    }).select().single();

    return _mapToCardEntity(response);
  }

  Stream<List<CardEntity>> watchCards(String deckId) {
    return _client
        .from('cards')
        .stream(primaryKey: ['id'])
        .eq('deck_id', deckId)
        .order('created_at')
        .map((rows) => rows.map((row) => _mapToCardEntity(row)).toList());
  }

  CardEntity _mapToCardEntity(Map<String, dynamic> row) {
    return CardEntity(
      id: row['id'] as String,
      deckId: row['deck_id'] as String,
      frontContent: row['front_content'] as String,
      backContent: row['back_content'] as String,
      frontImageUrl: row['front_image_url'] as String?,
      backImageUrl: row['back_image_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> deleteCard(String cardId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Uživatel není přihlášen');

    try {
      await _client
          .from('cards')
          .delete()
          .eq('id', cardId);
    } catch (e) {
      throw Exception('Chyba při mazání kartičky: $e');
    }
  }

  Future<List<CardEntity>> getCardsByIds(List<String> cardIds) async {
    if (cardIds.isEmpty) return [];
    
    final response = await _client
        .from('cards')
        .select()
        .inFilter('id', cardIds)
        .order('created_at');

    return response.map((row) => _mapToCardEntity(row)).toList();
  }

  Future<List<CardEntity>> getAllCards(String deckId) async {
    final response = await _client
        .from('cards')
        .select()
        .eq('deck_id', deckId)
        .order('created_at');

    return response.map((row) => _mapToCardEntity(row)).toList();
  }
} 