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
      
      await ref.read(folderRepositoryProvider.notifier).addDeckToFolder(
        folderId: folderId,
        deckId: deckId,
      );
      
      developer.log('Deck added successfully, invalidating providers', name: 'FolderList');
      ref.invalidateSelf();
      ref.invalidate(folderDeckListProvider(folderId));
      
      developer.log('Providers invalidated', name: 'FolderList');
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
      ref.invalidate(folderDeckListProvider);
    } catch (e) {
      throw Exception('Nepodařilo se odebrat balíček ze složky: $e');
    }
  }
}

@riverpod
Future<List<String>> folderDeckIds(FolderDeckIdsRef ref, String folderId) async {
  return ref.watch(folderRepositoryProvider.notifier).getFolderDeckIds(folderId);
} 