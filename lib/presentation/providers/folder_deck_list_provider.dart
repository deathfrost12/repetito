import 'dart:developer' as dev;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/deck_entity.dart';

part 'folder_deck_list_provider.g.dart';

@riverpod
Future<List<DeckEntity>> folderDeckList(FolderDeckListRef ref, String folderId) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  
  dev.log('Building FolderDeckList for folder: $folderId');
  
  if (currentUser == null) {
    dev.log('No current user found');
    return [];
  }

  try {
    // Nejdřív načteme data z folder_decks tabulky
    final folderDecksResponse = await supabase
        .from('folder_decks')
        .select('deck_id')
        .eq('folder_id', folderId);
        
    dev.log('Received folder_decks response: $folderDecksResponse');
    
    if (folderDecksResponse == null || folderDecksResponse.isEmpty) {
      dev.log('No folder_decks records found');
      return [];
    }

    // Extrahujeme ID balíčků
    final deckIds = <String>[];
    for (final record in folderDecksResponse) {
      final deckId = record['deck_id'];
      dev.log('Processing record deck_id: $deckId (${deckId.runtimeType})');
      
      if (deckId != null && deckId is String && deckId.isNotEmpty) {
        dev.log('Adding valid deck_id: $deckId');
        deckIds.add(deckId);
      }
    }
        
    dev.log('Extracted deck IDs: $deckIds');
    
    if (deckIds.isEmpty) {
      return [];
    }

    // Načteme detaily balíčků
    final decksResponse = await supabase
        .from('decks')
        .select()
        .inFilter('id', deckIds);
        
    dev.log('Received decks response: $decksResponse');

    final decks = <DeckEntity>[];
    for (final data in decksResponse) {
      try {
        if (data == null) continue;
        
        final id = data['id'] as String?;
        final name = data['name'] as String?;
        final createdAt = data['created_at'] as String?;
        final updatedAt = data['updated_at'] as String?;
        
        dev.log('Processing deck data: id=$id, name=$name, createdAt=$createdAt, updatedAt=$updatedAt');
        
        if (id == null || name == null || createdAt == null || updatedAt == null) {
          dev.log('Skipping invalid deck data');
          continue;
        }

        final deck = DeckEntity(
          id: id,
          userId: currentUser.id,
          name: name,
          description: data['description'] as String?,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
        );
        
        dev.log('Created DeckEntity: $deck');
        decks.add(deck);
      } catch (e) {
        dev.log('Error processing deck data: $e');
        continue;
      }
    }

    dev.log('Returning ${decks.length} decks');
    return decks;
  } catch (e, st) {
    dev.log('Error in FolderDeckList: $e\n$st');
    rethrow;
  }
} 