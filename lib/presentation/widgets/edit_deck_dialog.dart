import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/entities/deck_entity.dart';
import '../providers/deck_list_provider.dart';

class EditDeckDialog extends ConsumerWidget {
  final DeckEntity deck;

  const EditDeckDialog({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: deck.name);
    final descriptionController = TextEditingController(text: deck.description);
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(
        'Upravit balíček',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Název balíčku',
                hintText: 'např. Anglická slovíčka',
                labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
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
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Popis (volitelné)',
                hintText: 'např. Základní fráze a slovíčka',
                labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              maxLines: 2,
            ),
          ],
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
        FilledButton(
          onPressed: () async {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Balíček byl úspěšně upraven'),
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
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text(
            'Uložit',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
} 