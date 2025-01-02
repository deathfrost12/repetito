import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/folder_entity.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../providers/folder_list_provider.dart';
import '../../providers/deck_list_provider.dart';
import '../deck/deck_card.dart';

class FolderDetailScreen extends HookConsumerWidget {
  final FolderEntity folder;

  const FolderDetailScreen({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          folder.name,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.withOpacity(0.7),
            ),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: _FolderDetailContent(folder: folder),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeckDialog(context),
        backgroundColor: theme.colorScheme.primary,
        label: Text(
          'Přidat balíček',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implementovat dialog pro úpravu složky
  }

  void _showDeleteDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Smazat složku?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Opravdu chcete smazat složku "${folder.name}"? Tato akce je nevratná.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            child: const Text('Zrušit'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(folderListProvider.notifier).deleteFolder(folder.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.pop(); // Návrat na předchozí obrazovku
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Složka byla úspěšně smazána'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chyba: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Smazat',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final decksAsync = ref.watch(deckListProvider);
          
          return decksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AlertDialog(
              title: const Text('Chyba'),
              content: Text('$error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
            data: (decks) => AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text(
                'Přidat balíček do složky',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return ListTile(
                      title: Text(
                        deck.name,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      subtitle: deck.description != null
                          ? Text(
                              deck.description!,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            )
                          : null,
                      onTap: () async {
                        try {
                          await ref.read(folderListProvider.notifier).addDeckToFolder(
                            folderId: folder.id,
                            deckId: deck.id,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Balíček "${deck.name}" byl přidán do složky'),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chyba: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  child: const Text('Zrušit'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FolderDetailContent extends HookConsumerWidget {
  final FolderEntity folder;

  const _FolderDetailContent({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final decksAsync = ref.watch(deckListProvider);
    final folderDeckIdsAsync = ref.watch(folderDeckIdsProvider(folder.id));

    return decksAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Chyba: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (allDecks) => folderDeckIdsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Chyba: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (folderDeckIds) {
          final folderDecks = allDecks
              .where((deck) => folderDeckIds.contains(deck.id))
              .toList();

          if (folderDecks.isEmpty) {
            return _EmptyState(folder: folder);
          }

          return ListView.builder(
            cacheExtent: 100,
            itemCount: folderDecks.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final deck = folderDecks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    DeckCard(key: ValueKey(deck.id), deck: deck),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        onPressed: () => _showRemoveDeckDialog(context, deck),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRemoveDeckDialog(BuildContext context, DeckEntity deck) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Odebrat balíček ze složky?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Opravdu chcete odebrat balíček "${deck.name}" ze složky? Balíček nebude smazán.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            child: const Text('Zrušit'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(folderListProvider.notifier).removeDeckFromFolder(
                      folderId: folder.id,
                      deckId: deck.id,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Balíček "${deck.name}" byl odebrán ze složky'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chyba: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Odebrat',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final FolderEntity folder;

  const _EmptyState({required this.folder});

  @override
  Widget build(BuildContext context) {
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
              Icons.style_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Žádné balíčky',
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
          ),
        ],
      ),
    );
  }
} 