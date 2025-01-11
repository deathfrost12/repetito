import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/ai_deck_provider.dart';
import 'ai_generate_dialog.dart';
import 'dart:io' show File;
import 'package:image_picker/image_picker.dart';
import '../../providers/card_image_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddFlashcardDialog extends HookConsumerWidget {
  const AddFlashcardDialog({
    super.key,
    this.initialFront,
    this.initialBack,
    required this.cardIndex,
    required this.totalCards,
  });

  final String? initialFront;
  final String? initialBack;
  final int cardIndex;
  final int totalCards;

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref, String imageType) async {
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
        
        String tempCardId = cardListNotifier.getCardId(cardIndex);
        if (tempCardId.isEmpty) {
          tempCardId = const Uuid().v4();
          cardListNotifier.setCardId(cardIndex, tempCardId);
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

  void _showImageViewer(BuildContext context, String imageUrl, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pozadí
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black87,
              ),
            ),
            // Obrázek
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Křížek pro zavření
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );
    
    final frontController = useTextEditingController(text: initialFront);
    final backController = useTextEditingController(text: initialBack);
    final cardId = useState('');
    final showFrontImage = useState(false);
    final showBackImage = useState(false);

    // Inicializace cardId
    useEffect(() {
      cardId.value = ref.read(aICardListNotifierProvider.notifier).getCardId(cardIndex);
      return null;
    }, []);

    // Animace
    useEffect(() {
      animationController.repeat();
      return null;
    }, []);

    // Cleanup při zavření dialogu
    useEffect(() {
      return () {
        // Nechceme mazat obrázky při zavření dialogu
        // Obrázky zůstanou v temp úložišti a budou finalizovány při vytvoření balíčku
        // nebo smazány při smazání karty
      };
    }, [cardId.value]);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black54,
            ),
          ),
          Positioned(
            top: size.height * 0.25,
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                            if (frontController.text.isNotEmpty || backController.text.isNotEmpty) {
                              cardListNotifier.updateCard(
                                cardIndex,
                                frontController.text,
                                backController.text,
                              );
                              // Finalizujeme obrázky s aktuálním ID karty
                              if (cardId.value.isNotEmpty) {
                                ref.read(cardImageNotifierProvider.notifier)
                                    .finalizeTempImages(cardId.value, cardId.value);
                              }
                            } else {
                              // Pokud karta nemá obsah, smažeme obrázky
                              if (cardId.value.isNotEmpty) {
                                ref.read(cardImageNotifierProvider.notifier)
                                    .cleanupTempImages(cardId.value);
                              }
                            }
                            Navigator.of(context).pop();
                          },
                          color: theme.colorScheme.onSurface,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed: cardIndex > 0 ? () {
                                final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                cardListNotifier.updateCard(
                                  cardIndex,
                                  frontController.text,
                                  backController.text,
                                );
                                
                                Navigator.of(context).pop({
                                  'front': frontController.text,
                                  'back': backController.text,
                                });
                                showGeneralDialog<Map<String, String>>(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                  pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
                                    initialFront: ref.read(aICardListNotifierProvider)[cardIndex - 1]['front'],
                                    initialBack: ref.read(aICardListNotifierProvider)[cardIndex - 1]['back'],
                                    cardIndex: cardIndex - 1,
                                    totalCards: totalCards,
                                  ),
                                );
                              } : null,
                              color: theme.colorScheme.onSurface,
                            ),
                            Text(
                              '${cardIndex + 1}/$totalCards',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                cardIndex < totalCards - 1 
                                  ? Icons.keyboard_arrow_down
                                  : Icons.add
                              ),
                              onPressed: cardIndex < totalCards - 1 
                                ? () {
                                  final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                  cardListNotifier.updateCard(
                                    cardIndex,
                                    frontController.text,
                                    backController.text,
                                  );
                                  
                                  Navigator.of(context).pop();
                                  
                                  showGeneralDialog<Map<String, String>>(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                    pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
                                      initialFront: ref.read(aICardListNotifierProvider)[cardIndex + 1]['front'],
                                      initialBack: ref.read(aICardListNotifierProvider)[cardIndex + 1]['back'],
                                      cardIndex: cardIndex + 1,
                                      totalCards: totalCards,
                                    ),
                                  );
                                }
                                : () {
                                  final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                  cardListNotifier.updateCard(
                                    cardIndex,
                                    frontController.text,
                                    backController.text,
                                  );
                                  
                                  cardListNotifier.insertCard(cardIndex + 1);
                                  
                                  Navigator.of(context).pop();
                                  
                                  showGeneralDialog<Map<String, String>>(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                    pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
                                      cardIndex: cardIndex + 1,
                                      totalCards: totalCards + 1,
                                    ),
                                  );
                                },
                              color: theme.colorScheme.onSurface,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                          color: theme.colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // AI Generate Button
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const AIGenerateDialog(),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedBuilder(
                                    animation: animationController,
                                    builder: (context, child) {
                                      return Container(
                                  padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                      RotationTransition(
                                        turns: Tween(begin: 0.0, end: 1.0)
                                            .animate(animationController),
                                                  child: Icon(
                                                    Icons.auto_awesome,
                                                    color: theme.colorScheme.primary,
                                                    size: 20,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ShaderMask(
                                                shaderCallback: (bounds) {
                                                  return LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      theme.colorScheme.primary,
                                                      theme.colorScheme.primary.withBlue(
                                                  theme.colorScheme.primary.blue + 20,
                                                      ),
                                                    ],
                                                  ).createShader(bounds);
                                                },
                                          child: const Text(
                                                  'Zeptat AI na vytvoření kartičky',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                        // Front Content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zadejte výraz',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: frontController,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                            maxLines: null,
                                            decoration: InputDecoration(
                                              hintText: 'Zde začněte psát svůj výraz',
                                              hintStyle: TextStyle(
                                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                    if (cardId.value.isNotEmpty && showFrontImage.value)
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final imagesState = ref.watch(cardImageNotifierProvider);
                                              
                                              return imagesState.when(
                                                data: (images) {
                                                  final imageUrl = ref.read(cardImageNotifierProvider.notifier)
                                                      .getImageUrl(cardId.value, 'front');
                                                  if (imageUrl == null) {
                                                    showFrontImage.value = false;
                                                    return const SizedBox();
                                                  }
                                                  
                                                  return Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Image.network(
                                                      imageUrl,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          height: 150,
                                                          color: theme.colorScheme.surface,
                                                          child: const Center(
                                                            child: CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        height: 150,
                                                        color: theme.colorScheme.surface,
                                                        child: const Icon(Icons.error),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                loading: () => Container(
                                                  height: 150,
                                                  color: theme.colorScheme.surface,
                                                  child: const Center(child: CircularProgressIndicator()),
                                                ),
                                                error: (error, stack) => Container(
                                                  height: 150,
                                                  color: theme.colorScheme.surface,
                                                  child: Center(
                                                    child: Text(
                                                      'Chyba: $error',
                                                      style: TextStyle(color: theme.colorScheme.error),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                              const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionButton(
                                            icon: Icons.translate,
                                            label: 'Jazyk',
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.image_outlined,
                                            onTap: () => _pickAndUploadImage(context, ref, 'front'),
                                            theme: theme,
                                            hasImage: ref.watch(cardImageNotifierProvider).whenOrNull(
                                              data: (images) => ref.read(cardImageNotifierProvider.notifier)
                                                  .getImageUrl(cardId.value, 'front') != null,
                                            ) ?? false,
                                            onShowImage: () {
                                              final imageUrl = ref.read(cardImageNotifierProvider.notifier)
                                                  .getImageUrl(cardId.value, 'front');
                                              if (imageUrl != null) {
                                                _showImageViewer(context, imageUrl, theme);
                                              }
                                            },
                                            onDeleteImage: () {
                                              if (cardId.value.isNotEmpty) {
                                                ref.read(cardImageNotifierProvider.notifier)
                                                    .deleteImage(cardId.value, 'front');
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.mic,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.lightbulb_outline,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                        // Back Content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zadejte definici',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: backController,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                            maxLines: null,
                                            decoration: InputDecoration(
                                              hintText: 'Zde začněte psát definici',
                                              hintStyle: TextStyle(
                                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                    if (cardId.value.isNotEmpty && showBackImage.value)
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final imagesState = ref.watch(cardImageNotifierProvider);
                                              
                                              return imagesState.when(
                                                data: (images) {
                                                  final imageUrl = ref.read(cardImageNotifierProvider.notifier)
                                                      .getImageUrl(cardId.value, 'back');
                                                  if (imageUrl == null) {
                                                    showBackImage.value = false;
                                                    return const SizedBox();
                                                  }
                                                  
                                                  return Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Image.network(
                                                      imageUrl,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          height: 150,
                                                          color: theme.colorScheme.surface,
                                                          child: const Center(
                                                            child: CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        height: 150,
                                                        color: theme.colorScheme.surface,
                                                        child: const Icon(Icons.error),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                loading: () => Container(
                                                  height: 150,
                                                  color: theme.colorScheme.surface,
                                                  child: const Center(child: CircularProgressIndicator()),
                                                ),
                                                error: (error, stack) => Container(
                                                  height: 150,
                                                  color: theme.colorScheme.surface,
                                                  child: Center(
                                                    child: Text(
                                                      'Chyba: $error',
                                                      style: TextStyle(color: theme.colorScheme.error),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionButton(
                                            icon: Icons.translate,
                                            label: 'Jazyk',
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.image_outlined,
                                            onTap: () => _pickAndUploadImage(context, ref, 'back'),
                                            theme: theme,
                                            hasImage: ref.watch(cardImageNotifierProvider).whenOrNull(
                                              data: (images) => ref.read(cardImageNotifierProvider.notifier)
                                                  .getImageUrl(cardId.value, 'back') != null,
                                            ) ?? false,
                                            onShowImage: () {
                                              final imageUrl = ref.read(cardImageNotifierProvider.notifier)
                                                  .getImageUrl(cardId.value, 'back');
                                              if (imageUrl != null) {
                                                _showImageViewer(context, imageUrl, theme);
                                              }
                                            },
                                            onDeleteImage: () {
                                              if (cardId.value.isNotEmpty) {
                                                ref.read(cardImageNotifierProvider.notifier)
                                                    .deleteImage(cardId.value, 'back');
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.mic,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.lightbulb_outline,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  // Bottom Buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                    cardListNotifier.updateCard(
                                      cardIndex,
                                      frontController.text,
                                      backController.text,
                                    );
                                    
                                    // Finalizujeme obrázky s aktuálním ID karty
                                    if (cardId.value.isNotEmpty) {
                                      ref.read(cardImageNotifierProvider.notifier)
                                          .finalizeTempImages(cardId.value, cardId.value);
                                    }
                                    
                                    Navigator.of(context).pop();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                    foregroundColor: theme.colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: const Text('Přidat kartu'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton(
                                  onPressed: cardIndex < totalCards - 1 
                                    ? () {
                                      final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                      cardListNotifier.updateCard(
                                        cardIndex,
                                        frontController.text,
                                        backController.text,
                                      );
                                      
                                      Navigator.of(context).pop({
                                        'front': frontController.text,
                                        'back': backController.text,
                                      });
                                      showGeneralDialog<Map<String, String>>(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                        pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
                                          initialFront: ref.read(aICardListNotifierProvider)[cardIndex + 1]['front'],
                                          initialBack: ref.read(aICardListNotifierProvider)[cardIndex + 1]['back'],
                                          cardIndex: cardIndex + 1,
                                          totalCards: totalCards,
                                        ),
                                      );
                                    }
                                    : () {
                                      final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
                                      cardListNotifier.updateCard(
                                        cardIndex,
                                        frontController.text,
                                        backController.text,
                                      );
                                Navigator.of(context).pop();
                                    },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                              cardIndex < totalCards - 1 ? 'Další karta' : 'Uložit',
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isHighlighted;
  final bool hasImage;
  final VoidCallback? onShowImage;
  final VoidCallback? onDeleteImage;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onTap,
    required this.theme,
    this.isHighlighted = false,
    this.hasImage = false,
    this.onShowImage,
    this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () {
            if (hasImage) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.image_outlined,
                          color: theme.colorScheme.onSurface,
                        ),
                        title: Text(
                          'Zobrazit obrázek',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onShowImage?.call();
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Smazat obrázek',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onDeleteImage?.call();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            } else {
              onTap();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isHighlighted || hasImage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasImage)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '1',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 