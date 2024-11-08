import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../providers/deck_list_provider.dart';
import 'edit_deck_dialog.dart';

class DeckListScreen extends HookConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje balíčky'),
        centerTitle: true,
        actions: [
          // Tlačítko pro odhlášení
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                navigator.pop(); // Zavře případné dialogy
              }
            },
          ),
        ],
      ),
      // Tělo s prázdným stavem nebo seznamem balíčků
      body: const _DeckListContent(),
      // Tlačítko pro přidání nového balíčku
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateDeckDialog(context);
        },
        label: const Text('Nový balíček'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDeckDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nový balíček'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Název balíčku',
                  hintText: 'Např. Anglická slovíčka',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Prosím zadejte název balíčku';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Popis (volitelné)',
                  hintText: 'Např. Základní fráze a slovíčka',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zrušit'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final notifier = ref.watch(createDeckNotifierProvider);
              
              return FilledButton(
                onPressed: notifier.isLoading 
                    ? null 
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          await ref.read(createDeckNotifierProvider.notifier).createDeck(
                            nameController.text,
                            descriptionController.text.isEmpty 
                                ? null 
                                : descriptionController.text,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Balíček byl vytvořen'),
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
                child: notifier.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Vytvořit'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeckListContent extends HookConsumerWidget {
  const _DeckListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckListProvider.select((value) => value));
    
    return decksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Chyba: $error')),
      data: (decks) {
        if (decks.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          cacheExtent: 100,
          itemCount: decks.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final deck = decks[index];
            return DeckCard(key: ValueKey(deck.id), deck: deck);
          },
        );
      },
    );
  }
}

class DeckCard extends StatelessWidget {
  final DeckEntity deck;
  
  const DeckCard({super.key, required this.deck});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'deck_detail',
            pathParameters: {'id': deck.id},
            extra: deck,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (deck.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      deck.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _startStudy(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditDeckDialog(
        deck: deck,
        onUpdate: (_) {},
      ),
    );
  }

  void _startStudy(BuildContext context) {
    context.pushNamed(
      'study',
      pathParameters: {'deckId': deck.id},
      extra: deck,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Zatím nemáte žádné balíčky',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Začněte vytvořením nového balíčku pomocí tlačítka níže',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 