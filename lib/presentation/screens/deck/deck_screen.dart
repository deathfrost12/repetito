import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/ai_deck_provider.dart';
import '../../providers/card_image_provider.dart';
import 'add_flashcard_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class _CardItem extends ConsumerWidget {
  final Map<String, dynamic> card;
  final int index;
  final VoidCallback onTap;

  const _CardItem({
    required this.card,
    required this.index,
    required this.onTap,
  });

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref, String cardId, String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      try {
        // Získáme velikost souboru
        final bytes = await pickedFile.readAsBytes();
        final fileSize = bytes.length;
        
        if (fileSize > 2 * 1024 * 1024) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obrázek je příliš velký. Maximální velikost je 2MB')),
          );
          return;
        }

        final fileExtension = pickedFile.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension)) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Podporované formáty jsou pouze JPG, PNG a WebP')),
          );
          return;
        }

        // Vytvoříme dočasný soubor
        final tempDir = await getTemporaryDirectory();
        final tempPath = path.join(tempDir.path, '${const Uuid().v4()}.$fileExtension');
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
        final cardImageNotifier = ref.read(cardImageNotifierProvider.notifier);
        
        String tempCardId = cardId;
        if (tempCardId.isEmpty) {
          tempCardId = const Uuid().v4();
          cardListNotifier.setCardId(index, tempCardId);
        }
        
        await cardImageNotifier.uploadTempImage(tempCardId, imageType, tempFile);
        
        // Smažeme dočasný soubor
        await tempFile.delete();
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obrázek byl úspěšně nahrán')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepodařilo se nahrát obrázek: $e')),
        );
      }
    }
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return const Icon(Icons.error_outline, size: 48);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardId = ref.read(aICardListNotifierProvider.notifier).getCardId(index);
    final imageData = ref.watch(cardImageNotifierProvider);
    
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (cardId.isEmpty) return;
                    
                    imageData.whenOrNull(
                      data: (images) {
                        final cardImages = images[cardId];
                        if (cardImages == null || cardImages['front'] == null) {
                          _pickAndUploadImage(context, ref, cardId, 'front');
                        } else {
                          _showImageViewer(context, cardImages['front']!);
                        }
                      },
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageData.when(
                      data: (images) {
                        if (cardId.isEmpty) {
                          return const Icon(Icons.image_outlined, size: 24);
                        }
                        
                        final cardImages = images[cardId];
                        if (cardImages == null) {
                          return const Icon(Icons.image_outlined, size: 24);
                        }
                        
                        final imageUrl = cardImages['front'];
                        if (imageUrl == null) {
                          return const Icon(Icons.image_outlined, size: 24);
                        }
                        
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return const Icon(Icons.error_outline, size: 24);
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) {
                        print('Error loading image state: $error');
                        return const Icon(Icons.error_outline, size: 24);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Text(
                          card['front'] ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (card['back']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: onTap,
                                child: Text(
                                  card['back'] ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (cardId.isEmpty) return;
                                
                                imageData.whenOrNull(
                                  data: (images) {
                                    final cardImages = images[cardId];
                                    if (cardImages == null || cardImages['back'] == null) {
                                      _pickAndUploadImage(context, ref, cardId, 'back');
                                    } else {
                                      _showImageViewer(context, cardImages['back']!);
                                    }
                                  },
                                );
                              },
                              child: imageData.when(
                                data: (images) {
                                  if (cardId.isEmpty) return const SizedBox(width: 24);
                                  
                                  final cardImages = images[cardId];
                                  if (cardImages == null) {
                                    return Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    );
                                  }
                                  
                                  final imageUrl = cardImages['back'];
                                  if (imageUrl == null) {
                                    return Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    );
                                  }
                                  
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      imageUrl,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Center(
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading back image: $error');
                                        return Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(width: 24),
                                error: (_, __) => const SizedBox(width: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 