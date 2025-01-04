import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../domain/entities/folder_entity.dart';
import '../../../../domain/entities/deck_entity.dart';
import '../../../providers/deck_list_provider.dart';
import '../../../providers/folder_list_provider.dart';
import '../../../providers/folder_deck_list_provider.dart';
import '../../../providers/subfolder_list_provider.dart';
import 'deck_card.dart';
import 'folder_card.dart';
import 'dart:developer' as developer;

class FolderDetailContent extends HookConsumerWidget {
  final FolderEntity folder;

  const FolderDetailContent({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Sledujeme změny v seznamu podsložek
    final subfolders = ref.watch(subfolderListProvider(folder.id));
    
    // Sledujeme změny v seznamu balíčků a přidáme key pro vynucení rebuildu
    final decks = ref.watch(folderDeckListProvider(folder.id));
    
    // Přidáme listener pro automatické obnovení při změnách
    ref.listen<AsyncValue<List<DeckEntity>>>(
      folderDeckListProvider(folder.id),
      (previous, next) {
        developer.log(
          'Folder deck list changed: ${next.value?.length ?? 0} decks',
          name: 'FolderDetailContent',
        );
      },
    );
    
    developer.log('Building FolderDetailContent for folder: ${folder.id}', name: 'FolderDetailContent');
    developer.log('Current decks state: ${decks.value?.length ?? 0} decks', name: 'FolderDetailContent');

    return subfolders.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Chyba při načítání podsložek: $error'),
      ),
      data: (subfolderList) => decks.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Chyba při načítání balíčků: $error'),
        ),
        data: (deckList) {
          developer.log('Rendering folder content with ${subfolderList.length} subfolders and ${deckList.length} decks', name: 'FolderDetailContent');
          
          if (subfolderList.isEmpty && deckList.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView(
            key: ValueKey('folder_content_${folder.id}_${deckList.length}'),
            cacheExtent: 100,
            padding: const EdgeInsets.all(16),
            children: [
              if (subfolderList.isNotEmpty) ...[
                Text(
                  'Podsložky',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...subfolderList.map((subfolder) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FolderCard(folder: subfolder),
                )),
                const SizedBox(height: 24),
              ],
              if (deckList.isNotEmpty) ...[
                Text(
                  'Balíčky',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...deckList.map((deck) {
                  developer.log('Rendering deck card: ${deck.id} with folder ID: ${folder.id}', name: 'FolderDetailContent');
                  return Padding(
                    key: ValueKey('deck_${deck.id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeckCard(
                      deck: deck,
                      currentFolderId: folder.id,
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Prázdná složka',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Přidejte balíčky do složky "${folder.name}"',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 