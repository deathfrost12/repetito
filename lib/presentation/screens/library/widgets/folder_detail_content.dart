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

class FolderDetailContent extends HookConsumerWidget {
  final FolderEntity folder;

  const FolderDetailContent({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subfolders = ref.watch(subfolderListProvider(folder.id));
    final decks = ref.watch(folderDeckListProvider(folder.id));

    return subfolders.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Chyba při načítání obsahu složky',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (subfolderList) => decks.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Chyba při načítání balíčků',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (deckList) {
          if (subfolderList.isEmpty && deckList.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
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
                ...deckList.map((deck) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeckCard(deck: deck),
                )),
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