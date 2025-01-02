import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:repetito/data/repositories/folder_repository.dart';
import 'package:repetito/domain/entities/folder_entity.dart';

part 'folder_list_provider.g.dart';

@riverpod
class FolderList extends _$FolderList {
  @override
  Future<List<FolderEntity>> build() async {
    return ref.watch(folderRepositoryProvider.notifier).getFolders();
  }

  Future<void> createFolder({
    required String name,
    required String color,
    required String icon,
    String? description,
  }) async {
    await ref.read(folderRepositoryProvider.notifier).createFolder(
          name: name,
          color: color,
          icon: icon,
          description: description,
        );
    ref.invalidateSelf();
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
    await ref.read(folderRepositoryProvider.notifier).addDeckToFolder(
          folderId: folderId,
          deckId: deckId,
        );
    ref.invalidateSelf();
  }

  Future<void> removeDeckFromFolder({
    required String folderId,
    required String deckId,
  }) async {
    await ref.read(folderRepositoryProvider.notifier).removeDeckFromFolder(
          folderId: folderId,
          deckId: deckId,
        );
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<String>> folderDeckIds(FolderDeckIdsRef ref, String folderId) async {
  return ref.watch(folderRepositoryProvider.notifier).getFolderDeckIds(folderId);
} 