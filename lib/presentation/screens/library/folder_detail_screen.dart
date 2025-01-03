import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/folder_entity.dart';
import '../../providers/folder_list_provider.dart';
import '../../providers/subfolder_list_provider.dart';
import '../../providers/deck_list_provider.dart';
import '../../providers/folder_deck_list_provider.dart';
import '../../../data/repositories/folder_hierarchy_repository.dart';
import '../../../data/repositories/folder_repository.dart';
import 'widgets/folder_detail_content.dart';
import 'dart:developer' as developer;

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
      body: FolderDetailContent(folder: folder),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: theme.colorScheme.primary,
        label: Text(
          'Přidat',
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

  void _showAddDialog(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('Nová podsložka'),
            onTap: () {
              Navigator.of(context).pop();
              _showCreateFolderDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: const Text('Přidat balíček'),
            onTap: () {
              Navigator.of(context).pop();
              _showAddDeckDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedColor = 'blue';
    String selectedIcon = 'folder';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Nová podsložka',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Název složky',
                      hintText: 'např. Jazyky',
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
                        return 'Prosím zadejte název složky';
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
                      hintText: 'např. Balíčky pro studium jazyků',
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
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barva:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'blue',
                            'red',
                            'green',
                            'purple',
                            'orange',
                          ].map((color) => InkWell(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getColor(color),
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ikona:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'folder',
                            'school',
                            'language',
                            'science',
                            'history',
                          ].map((iconName) => InkWell(
                            onTap: () => setState(() => selectedIcon = iconName),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedIcon == iconName
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconData(iconName),
                                color: selectedIcon == iconName
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            Consumer(
              builder: (context, ref, child) {
                return FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      // Vytvoříme novou složku
                      final newFolder = await ref.read(folderListProvider.notifier).createFolder(
                        name: nameController.text,
                        color: selectedColor,
                        icon: selectedIcon,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      );

                      // Přidáme ji jako podsložku
                      try {
                        final repository = FolderHierarchyRepository();
                        final success = await repository.addSubfolder(folder.id, newFolder.id);

                        if (success) {
                          // Aktualizujeme seznam podsložek
                          ref.invalidate(subfolderListProvider(folder.id));

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Podsložka byla úspěšně vytvořena'),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          }
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
                    'Vytvořit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return ref.watch(deckListProvider).when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
            error: (error, stack) => AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text(
                'Chyba při načítání balíčků',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              content: Text(
                error.toString(),
                style: TextStyle(color: theme.colorScheme.error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  child: const Text('Zavřít'),
                ),
              ],
            ),
            data: (decks) {
              if (decks.isEmpty) {
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Text(
                    'Žádné balíčky',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  content: Text(
                    'Nejprve vytvořte nějaké balíčky, které můžete přidat do složky.',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      child: const Text('Zavřít'),
                    ),
                  ],
                );
              }

              return AlertDialog(
                backgroundColor: theme.cardColor,
                title: Text(
                  'Přidat balíček',
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
                            developer.log('Adding deck ${deck.id} to folder ${folder.id}', name: 'FolderDetailScreen');
                            
                            await ref.read(folderRepositoryProvider.notifier).addDeckToFolder(
                              folderId: folder.id,
                              deckId: deck.id,
                            );
                            
                            developer.log('Deck added successfully, invalidating providers', name: 'FolderDetailScreen');
                            
                            // Aktualizujeme seznam balíčků ve složce
                            ref.invalidate(folderDeckListProvider(folder.id));
                            
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Balíček "${deck.name}" byl přidán do složky'),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                              developer.log('UI updated after adding deck', name: 'FolderDetailScreen');
                            }
                          } catch (e, stack) {
                            developer.log(
                              'Error adding deck to folder: $e',
                              name: 'FolderDetailScreen',
                              error: e,
                              stackTrace: stack
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chyba: $e'),
                                  backgroundColor: theme.colorScheme.error,
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
                    child: const Text('Zavřít'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: folder.name);
    final descriptionController = TextEditingController(text: folder.description ?? '');
    final formKey = GlobalKey<FormState>();
    String selectedColor = folder.color;
    String selectedIcon = folder.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Upravit složku',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Název složky',
                      hintText: 'např. Jazyky',
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
                        return 'Prosím zadejte název složky';
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
                      hintText: 'např. Balíčky pro studium jazyků',
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
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barva:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'blue',
                            'red',
                            'green',
                            'purple',
                            'orange',
                          ].map((color) => InkWell(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getColor(color),
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ikona:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'folder',
                            'school',
                            'language',
                            'science',
                            'history',
                          ].map((iconName) => InkWell(
                            onTap: () => setState(() => selectedIcon = iconName),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedIcon == iconName
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconData(iconName),
                                color: selectedIcon == iconName
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            Consumer(
              builder: (context, ref, child) {
                return FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      await ref.read(folderListProvider.notifier).updateFolder(
                        id: folder.id,
                        name: nameController.text,
                        color: selectedColor,
                        icon: selectedIcon,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Složka byla úspěšně upravena'),
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
                );
              },
            ),
          ],
        ),
      ),
    );
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

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'folder':
        return Icons.folder_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'language':
        return Icons.language_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
} 