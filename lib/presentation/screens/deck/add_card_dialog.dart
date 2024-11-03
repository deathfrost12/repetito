import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../providers/card_list_provider.dart';

class AddCardDialog extends ConsumerWidget {
  final DeckEntity deck;

  const AddCardDialog({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text('Nová kartička'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: frontController,
              decoration: const InputDecoration(
                labelText: 'Přední strana',
                hintText: 'Např. Hello',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Prosím zadejte text přední strany';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: backController,
              decoration: const InputDecoration(
                labelText: 'Zadní strana',
                hintText: 'Např. Ahoj',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Prosím zadejte text zadní strany';
                }
                return null;
              },
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
            final notifier = ref.watch(createCardNotifierProvider);
            
            return FilledButton(
              onPressed: notifier.isLoading 
                  ? null 
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      try {
                        await ref.read(createCardNotifierProvider.notifier).createCard(
                          deckId: deck.id,
                          frontContent: frontController.text,
                          backContent: backController.text,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kartička byla vytvořena'),
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
    );
  }
} 