import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:repetito/data/repositories/folder_repository.dart';
import 'package:repetito/domain/entities/folder_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'folder_deck_list_provider.dart';
import 'dart:developer' as developer;

part 'folder_list_provider.g.dart';

@riverpod
class FolderList extends _$FolderList {
  @override
  Future<List<FolderEntity>> build() async {
    return ref.watch(folderRepositoryProvider.notifier).getFolders();
  }

  Future<FolderEntity> createFolder({
    required String name,
    required String color,
    required String icon,
    String? description,
  }) async {
    final folder = await ref.read(folderRepositoryProvider.notifier).createFolder(
          name: name,
          color: color,
          icon: icon,
          description: description,
        );
    ref.invalidateSelf();
    return folder;
  }

  Future<void> updateFolder({
    required String id,
    String? name,
    String? color,
    String? icon,
    String? description,
  }) async {
    await ref.read(folderRepositoryProvider.notifier).updateFolder(
          id: id,
          name: name,
          color: color,
          icon: icon,
          description: description,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteFolder(String id) async {
    await ref.read(folderRepositoryProvider.notifier).deleteFolder(id);
    ref.invalidateSelf();
  }

  Future<void> addDeckToFolder({
    required String folderId,
    required String deckId,
  }) async {
    try {
      developer.log('Starting addDeckToFolder in FolderList provider', name: 'FolderList');
      developer.log('Adding deck $deckId to folder $folderId', name: 'FolderList');
      
      // Nejdřív získáme aktuální stav
      final currentState = await ref.read(folderDeckListProvider(folderId).future);
      developer.log('Current state: ${currentState.length} decks in folder', name: 'FolderList');
      
      // Přidáme balíček do složky
      await ref.read(folderRepositoryProvider.notifier).addDeckToFolder(
        folderId: folderId,
        deckId: deckId,
      );
      
      developer.log('Deck added successfully, invalidating providers', name: 'FolderList');
      
      // Invalidujeme providery
      ref.invalidateSelf();
      ref.invalidate(folderDeckListProvider(folderId));
      
      // Počkáme na aktualizaci a ověříme stav
      final newState = await ref.read(folderDeckListProvider(folderId).future);
      developer.log('New state: ${newState.length} decks in folder', name: 'FolderList');
      
      final deckAdded = newState.any((d) => d.id == deckId);
      developer.log('Deck was added: $deckAdded', name: 'FolderList');
      
      if (!deckAdded) {
        throw Exception('Balíček nebyl přidán do složky');
      }
      
      developer.log('Operation completed successfully', name: 'FolderList');
    } catch (e, stack) {
      developer.log(
        'Error adding deck to folder: $e',
        name: 'FolderList',
        error: e,
        stackTrace: stack
      );
      throw Exception('Nepodařilo se přidat balíček do složky: $e');
    }
  }

  Future<void> removeDeckFromFolder({
    required String folderId,
    required String deckId,
  }) async {
    try {
      await ref.read(folderRepositoryProvider.notifier).removeDeckFromFolder(
        folderId: folderId,
        deckId: deckId,
      );
      ref.invalidateSelf();
      ref.invalidate(folderDeckListProvider(folderId));
    } catch (e) {
      throw Exception('Nepodařilo se odebrat balíček ze složky: $e');
    }
  }
}

@riverpod
Future<List<String>> folderDeckIds(FolderDeckIdsRef ref, String folderId) async {
  return ref.watch(folderRepositoryProvider.notifier).getFolderDeckIds(folderId);
} 