import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repetito/domain/entities/deck_entity.dart';
import 'package:repetito/presentation/providers/deck_list_provider.dart';
import 'package:repetito/presentation/providers/folder_list_provider.dart';
import 'package:repetito/presentation/widgets/confirm_dialog.dart';
import 'package:repetito/presentation/widgets/edit_deck_dialog.dart';
import 'package:repetito/presentation/providers/folder_deck_list_provider.dart';
import 'package:repetito/presentation/providers/deck_selection_provider.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class DeckCard extends ConsumerWidget {
  const DeckCard({
    super.key,
    required this.deck,
    this.currentFolderId,
  });

  final DeckEntity deck;
  final String? currentFolderId;

  Future<void> _duplicateDeck(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Vytvoříme kopii balíčku
      final newDeck = await ref.read(createDeckNotifierProvider.notifier).createDeck(
        deck.name + ' (kopie)',
        deck.description,
      );
      
      // 2. Pokud jsme ve složce, přidáme balíček do složky přímo přes Supabase
      if (currentFolderId != null) {
        final supabase = Supabase.instance.client;
        
        await supabase
            .from('folder_decks')
            .insert({
              'folder_id': currentFolderId,
              'deck_id': newDeck.id,
              'created_at': DateTime.now().toIso8601String(),
            });
      }
      
      // 3. Aktualizujeme UI
      ref.invalidate(deckListProvider);
      if (currentFolderId != null) {
        ref.invalidate(folderDeckListProvider(currentFolderId!));
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balíček byl úspěšně duplikován'),
          ),
        );
      }
    } catch (e) {
      developer.log('Error duplicating deck: $e', name: 'DeckCard');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nepodařilo se duplikovat balíček: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectionState = ref.watch(deckSelectionControllerProvider);
    final isSelected = selectionState.selectedDecks.contains(deck);

    return InkWell(
      onLongPress: () => _showContextMenu(context, ref),
      onTap: () {
        if (selectionState.isSelecting) {
          ref.read(deckSelectionControllerProvider.notifier).toggleDeckSelection(deck);
        } else {
          context.pushNamed(
            'deck_detail',
            pathParameters: {'id': deck.id},
            extra: deck,
          );
        }
      },
      child: Card(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (deck.description != null && deck.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      deck.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Vytvořeno: ${_formatDate(deck.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, WidgetRef ref) async {
    developer.log('Showing context menu', name: 'DeckCard');
    developer.log('Current folder ID: $currentFolderId', name: 'DeckCard');
    
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('Vybrat'),
              onTap: () {
                developer.log('Selected: select', name: 'DeckCard');
                ref.read(deckSelectionControllerProvider.notifier).toggleDeckSelection(deck);
                Navigator.pop(context, 'select');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Upravit'),
              onTap: () {
                developer.log('Selected: edit', name: 'DeckCard');
                Navigator.pop(context, 'edit');
              },
            ),
            if (currentFolderId != null)
              ListTile(
                leading: const Icon(Icons.folder_off),
                title: const Text('Odebrat ze složky'),
                onTap: () {
                  developer.log('Selected: remove', name: 'DeckCard');
                  Navigator.pop(context, 'remove');
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplikovat'),
              onTap: () {
                developer.log('Selected: duplicate', name: 'DeckCard');
                Navigator.pop(context, 'duplicate');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Smazat'),
              onTap: () {
                developer.log('Selected: delete', name: 'DeckCard');
                Navigator.pop(context, 'delete');
              },
            ),
          ],
        ),
      ),
    );

    developer.log('Context menu result: $result', name: 'DeckCard');
    if (!context.mounted) return;

    switch (result) {
      case 'edit':
        await showDialog(
          context: context,
          builder: (context) => EditDeckDialog(deck: deck),
        );
        break;
      case 'remove':
        if (currentFolderId != null) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmDialog(
              title: 'Odebrat ze složky',
              content: 'Opravdu chcete odebrat balíček ze složky?',
              confirmLabel: 'Odebrat',
              cancelLabel: 'Zrušit',
            ),
          );

          developer.log('Remove confirmed: $confirmed', name: 'DeckCard');
          if (confirmed == true) {
            try {
              await ref.read(folderDeckListProvider(currentFolderId!).notifier).removeDeck(
                currentFolderId!,
                deck.id,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Balíček byl odebrán ze složky'),
                  ),
                );
              }
            } catch (e) {
              developer.log('Error removing deck from folder: $e', name: 'DeckCard');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nepodařilo se odebrat balíček ze složky: $e'),
                  ),
                );
              }
            }
          }
        }
        break;
      case 'duplicate':
        await _duplicateDeck(context, ref);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmDialog(
            title: 'Smazat balíček',
            content: 'Opravdu chcete smazat balíček? Tato akce je nevratná.',
            confirmLabel: 'Smazat',
            cancelLabel: 'Zrušit',
          ),
        );

        developer.log('Delete confirmed: $confirmed', name: 'DeckCard');
        if (confirmed == true) {
          try {
            await ref.read(deleteDeckNotifierProvider.notifier).deleteDeck(deck.id);
            ref.invalidate(deckListProvider);
            if (currentFolderId != null) {
              ref.invalidate(folderDeckListProvider(currentFolderId!));
              await ref.read(folderDeckListProvider(currentFolderId!).future);
            }
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Balíček byl smazán'),
                ),
              );
            }
          } catch (e) {
            developer.log('Error deleting deck: $e', name: 'DeckCard');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nepodařilo se smazat balíček: $e'),
                ),
              );
            }
          }
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
} 