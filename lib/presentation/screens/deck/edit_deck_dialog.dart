import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../providers/deck_list_provider.dart';
import '../../../data/repositories/deck_repository.dart';

class EditDeckDialog extends ConsumerWidget {
  final DeckEntity deck;
  final Function(DeckEntity)? onUpdate;

  const EditDeckDialog({
    super.key,
    required this.deck,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: deck.name);
    final descriptionController = TextEditingController(text: deck.description);
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text('Upravit balíček'),
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
            final notifier = ref.watch(updateDeckNotifierProvider);
            
            return FilledButton(
              onPressed: notifier.isLoading 
                  ? null 
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      try {
                        await ref.read(updateDeckNotifierProvider.notifier).updateDeck(
                          deckId: deck.id,
                          name: nameController.text,
                          description: descriptionController.text.isEmpty 
                              ? null 
                              : descriptionController.text,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          
                          final updatedDeck = await ref.read(deckRepositoryProvider).getDeck(deck.id);
                          onUpdate?.call(updatedDeck);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Balíček byl upraven'),
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
                  : const Text('Uložit'),
            );
          },
        ),
      ],
    );
  }
} 