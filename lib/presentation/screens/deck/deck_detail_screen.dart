import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/card_list_provider.dart';
import 'edit_deck_dialog.dart';
import 'add_card_dialog.dart';
import '../statistics/study_statistics_screen.dart';

class DeckDetailScreen extends HookConsumerWidget {
  final DeckEntity deck;

  const DeckDetailScreen({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.pathHome);
            }
          },
        ),
        title: Text(deck.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => EditDeckDialog(
                  deck: deck,
                  onUpdate: (updatedDeck) {
                    if (context.mounted) {
                      context.go(
                        '/deck/${deck.id}',
                        extra: updatedDeck,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deck.description?.isNotEmpty ?? false) ...[
                  Text(
                    deck.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Vytvořeno ${_formatDate(deck.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        'study',
                        pathParameters: {'deckId': deck.id},
                        extra: deck,
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Začít studium'),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudyStatisticsScreen(deck: deck),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'Statistiky',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kartičky',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final cardsAsync = ref.watch(cardListProvider(deck.id));
                
                return cardsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Chyba: $error'),
                  ),
                  data: (cards) {
                    if (cards.isEmpty) {
                      return const Center(
                        child: Text('Zatím nemáte žádné kartičky'),
                      );
                    }

                    return ListView.builder(
                      itemCount: cards.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Card(
                          child: ListTile(
                            title: Text(card.frontContent),
                            subtitle: Text(card.backContent),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Smazat kartičku?'),
                                    content: const Text('Opravdu chcete smazat tuto kartičku?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Zrušit'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Smazat'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true && context.mounted) {
                                  try {
                                    await ref.read(deleteCardNotifierProvider.notifier).deleteCard(
                                      card.id,
                                      deck.id,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Kartička byla smazána'),
                                          action: SnackBarAction(
                                            label: 'Vrátit zpět',
                                            onPressed: () async {
                                              try {
                                                await ref.read(createCardNotifierProvider.notifier).createCard(
                                                  deckId: deck.id,
                                                  frontContent: card.frontContent,
                                                  backContent: card.backContent,
                                                );
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Chyba při obnovení kartičky: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (_) {}
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddCardDialog(deck: deck),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
} 