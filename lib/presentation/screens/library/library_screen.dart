import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/folder_entity.dart';
import '../../../domain/enums/library_view_type.dart';
import '../../providers/folder_list_provider.dart';
import '../../providers/library_view_provider.dart';
import 'widgets/folder_card.dart';
import 'widgets/folder_grid_card.dart';

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSearching = useState(false);
    final searchController = useTextEditingController();
    final sortOption = useState<SortOption>(SortOption.nameAsc);
    final viewType = ref.watch(libraryViewControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: isSearching.value
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                hintText: 'Hledat složky...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    isSearching.value = false;
                    searchController.clear();
                  },
                ),
              ),
            )
          : Text(
              'Knihovna',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
        elevation: 0,
        actions: [
          if (!isSearching.value) ...[
            IconButton(
              icon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onPressed: () => isSearching.value = true,
            ),
            IconButton(
              icon: Icon(
                viewType.icon,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onPressed: () => ref.read(libraryViewControllerProvider.notifier).toggleView(),
            ),
            PopupMenuButton<SortOption>(
              icon: Icon(
                Icons.sort,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onSelected: (option) => sortOption.value = option,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOption.nameAsc,
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha),
                      SizedBox(width: 12),
                      Text('Název (A-Z)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: SortOption.nameDesc,
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha),
                      SizedBox(width: 12),
                      Text('Název (Z-A)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: SortOption.dateAsc,
                  child: Row(
                    children: [
                      Icon(Icons.access_time),
                      SizedBox(width: 12),
                      Text('Nejstarší'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: SortOption.dateDesc,
                  child: Row(
                    children: [
                      Icon(Icons.access_time),
                      SizedBox(width: 12),
                      Text('Nejnovější'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _LibraryContent(
        searchQuery: searchController.text,
        sortOption: sortOption.value,
      ),
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

enum SortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
}

class _LibraryContent extends HookConsumerWidget {
  final String searchQuery;
  final SortOption sortOption;

  const _LibraryContent({
    required this.searchQuery,
    required this.sortOption,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderListProvider);
    final viewType = ref.watch(libraryViewControllerProvider);
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
        // Filtrování podle vyhledávání
        var filteredFolders = folders;
        if (searchQuery.isNotEmpty) {
          filteredFolders = folders.where((folder) =>
            folder.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (folder.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
          ).toList();
        }

        // Řazení
        switch (sortOption) {
          case SortOption.nameAsc:
            filteredFolders.sort((a, b) => a.name.compareTo(b.name));
          case SortOption.nameDesc:
            filteredFolders.sort((a, b) => b.name.compareTo(a.name));
          case SortOption.dateAsc:
            filteredFolders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          case SortOption.dateDesc:
            filteredFolders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        if (filteredFolders.isEmpty) {
          if (searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Žádné složky neodpovídají\nvašemu vyhledávání',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          return const _EmptyState();
        }

        switch (viewType) {
          case LibraryViewType.list:
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                // TODO: Implementovat změnu pořadí složek
              },
              padding: const EdgeInsets.all(16),
              itemCount: filteredFolders.length,
              itemBuilder: (context, index) {
                final folder = filteredFolders[index];
                return Padding(
                  key: ValueKey(folder.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.drag_indicator,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FolderCard(folder: folder),
                      ),
                    ],
                  ),
                );
              },
            );
          case LibraryViewType.grid:
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredFolders.length,
              itemBuilder: (context, index) {
                final folder = filteredFolders[index];
                return FolderGridCard(folder: folder);
              },
            );
        }
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

class FolderCard extends ConsumerWidget {
  final FolderEntity folder;
  
  const FolderCard({super.key, required this.folder});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref),
      child: Card(
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
        child: Stack(
          children: [
            InkWell(
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
                                onPressed: () => _showEditDialog(context, ref),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                onPressed: () => _showDeleteDialog(context, ref),
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
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Upravit',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditDialog(context, ref);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.content_copy_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Duplikovat',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  try {
                    await ref.read(folderListProvider.notifier).createFolder(
                      name: '${folder.name} (kopie)',
                      color: folder.color,
                      icon: folder.icon,
                      description: folder.description,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Složka byla úspěšně duplikována'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chyba: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: Text(
                  'Smazat',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
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
          'Opravdu chcete smazat složku "${folder.name}"?\nTato akce je nevratná.',
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
          FilledButton(
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
                  Navigator.of(context).pop();
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
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Popis (volitelné)',
                      hintText: 'např. Složka pro jazykové kartičky',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
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
            FilledButton(
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