import 'dart:developer' as dev;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/deck_entity.dart';

part 'folder_deck_list_provider.g.dart';

@riverpod
class FolderDeckList extends _$FolderDeckList {
  @override
  Future<List<DeckEntity>> build(String folderId) async {
    return _loadDecks(folderId);
  }

  Future<List<DeckEntity>> _loadDecks(String folderId) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    dev.log('Loading folder decks for folder: $folderId', name: 'FolderDeckList');
    
    if (currentUser == null) {
      dev.log('No current user found', name: 'FolderDeckList');
      return [];
    }

    try {
      // Načteme vazby mezi složkou a balíčky
      final folderDecksResponse = await supabase
          .from('folder_decks')
          .select('deck_id')
          .eq('folder_id', folderId);
          
      dev.log('Got folder_decks response: $folderDecksResponse', name: 'FolderDeckList');
      
      if (folderDecksResponse == null || folderDecksResponse.isEmpty) {
        dev.log('No folder_decks records found', name: 'FolderDeckList');
        return [];
      }

      // Extrahujeme ID balíčků
      final deckIds = folderDecksResponse
          .map((record) => record['deck_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
          
      dev.log('Extracted deck IDs: $deckIds', name: 'FolderDeckList');
      
      if (deckIds.isEmpty) {
        dev.log('No valid deck IDs found', name: 'FolderDeckList');
        return [];
      }

      // Načteme detaily balíčků
      final decksResponse = await supabase
          .from('decks')
          .select()
          .inFilter('id', deckIds);
          
      dev.log('Received decks response: $decksResponse', name: 'FolderDeckList');

      final decks = decksResponse.map((data) {
        try {
          final id = data['id'] as String?;
          final name = data['name'] as String?;
          final createdAt = data['created_at'] as String?;
          final updatedAt = data['updated_at'] as String?;
          
          if (id == null || name == null || createdAt == null || updatedAt == null) {
            dev.log('Skipping invalid deck data', name: 'FolderDeckList');
            return null;
          }

          return DeckEntity(
            id: id,
            userId: currentUser.id,
            name: name,
            description: data['description'] as String?,
            createdAt: DateTime.parse(createdAt),
            updatedAt: DateTime.parse(updatedAt),
          );
        } catch (e) {
          dev.log('Error processing deck data: $e', name: 'FolderDeckList');
          return null;
        }
      })
      .whereType<DeckEntity>()
      .toList();
      
      dev.log('Returning ${decks.length} decks', name: 'FolderDeckList');
      return decks;
    } catch (e, stack) {
      dev.log(
        'Error loading folder decks data: $e',
        name: 'FolderDeckList',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Nepodařilo se načíst balíčky ve složce: $e');
    }
  }

  Future<void> addDeck(String folderId, String deckId) async {
    final supabase = Supabase.instance.client;
    
    try {
      dev.log('Adding deck $deckId to folder $folderId', name: 'FolderDeckList');
      
      await supabase
          .from('folder_decks')
          .upsert({
            'folder_id': folderId,
            'deck_id': deckId,
            'created_at': DateTime.now().toIso8601String(),
          });
          
      dev.log('Deck added successfully, refreshing state', name: 'FolderDeckList');
      ref.invalidateSelf();
      
    } catch (e, stack) {
      dev.log(
        'Error adding deck to folder: $e',
        name: 'FolderDeckList',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Nepodařilo se přidat balíček do složky: $e');
    }
  }

  Future<void> removeDeck(String folderId, String deckId) async {
    final supabase = Supabase.instance.client;
    
    try {
      dev.log('Removing deck $deckId from folder $folderId', name: 'FolderDeckList');
      
      await supabase
          .from('folder_decks')
          .delete()
          .eq('folder_id', folderId)
          .eq('deck_id', deckId);
          
      dev.log('Deck removed successfully, refreshing state', name: 'FolderDeckList');
      ref.invalidateSelf();
      
    } catch (e, stack) {
      dev.log(
        'Error removing deck from folder: $e',
        name: 'FolderDeckList',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Nepodařilo se odebrat balíček ze složky: $e');
    }
  }
} 