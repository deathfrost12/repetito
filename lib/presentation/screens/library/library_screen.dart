import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/folder_entity.dart';
import '../../providers/folder_list_provider.dart';

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Knihovna',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: const _LibraryContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderDialog(context),
        backgroundColor: theme.colorScheme.primary,
        label: Text(
          'Nová složka',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(
          Icons.create_new_folder_outlined,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedColor = 'blue';
    String selectedIcon = 'folder';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Nová složka',
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
                      await ref.read(folderListProvider.notifier).createFolder(
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
                            content: const Text('Složka byla úspěšně vytvořena'),
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

class _LibraryContent extends HookConsumerWidget {
  const _LibraryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderListProvider);
    final theme = Theme.of(context);
    
    return foldersAsync.when(
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
      data: (folders) {
        if (folders.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          cacheExtent: 100,
          itemCount: folders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FolderCard(key: ValueKey(folder.id), folder: folder),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.folder_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Žádné složky',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vytvořte si první složku pro organizaci balíčků',
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

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  
  const FolderCard({super.key, required this.folder});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'folder_detail',
            pathParameters: {'id': folder.id},
            extra: folder,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColor(folder.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconData(folder.icon),
                        color: _getColor(folder.color),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (folder.description?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              folder.description!,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vytvořeno ${_formatDate(folder.createdAt)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
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
                  ],
                ),
              ],
            ),
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
} 