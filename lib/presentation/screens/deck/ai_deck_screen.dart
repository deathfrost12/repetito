import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/card_repository.dart';
import '../../providers/deck_list_provider.dart';
import '../../providers/card_list_provider.dart';
import '../../providers/ai_deck_provider.dart';
import 'add_flashcard_dialog.dart';
import 'ai_generate_dialog.dart';
import 'dart:developer' as dev;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../../presentation/providers/card_image_provider.dart';

class AIDeckScreen extends StatefulHookConsumerWidget {
  const AIDeckScreen({super.key});

  @override
  ConsumerState<AIDeckScreen> createState() => _AIDeckScreenState();
}

class _AIDeckScreenState extends ConsumerState<AIDeckScreen> {
  late final TextEditingController cardFrontController;
  late final TextEditingController cardBackController;

  @override
  void initState() {
    super.initState();
    cardFrontController = TextEditingController();
    cardBackController = TextEditingController();
  }

  @override
  void dispose() {
    cardFrontController.dispose();
    cardBackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final promptController = useTextEditingController();
    final formKey = GlobalKey<FormState>();
    final showDescription = useState(false);
    final isCreating = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    useEffect(() {
      cardFrontController.clear();
      cardBackController.clear();
      animationController.repeat();
      return null;
    }, []);

    Future<void> createDeck() async {
      if (!formKey.currentState!.validate() || isCreating.value) return;

      isCreating.value = true;
      try {
        dev.log('Začínám vytvářet AI balíček', name: 'AIDeckScreen');
        
        final cardList = ref.read(aICardListNotifierProvider);
        final deck = await ref.read(createAIDeckNotifierProvider.notifier).createDeck(
          name: nameController.text,
          description: descriptionController.text.isEmpty ? null : descriptionController.text,
          cards: cardList,
        );

        dev.log('AI balíček vytvořen: ${deck.id}', name: 'AIDeckScreen');
        
        if (!context.mounted) return;
        
        dev.log('Navigace na hlavní stránku', name: 'AIDeckScreen');
        Navigator.of(context).pop();
      } catch (e) {
        dev.log(
          'Chyba při vytváření AI balíčku: $e',
          name: 'AIDeckScreen',
          error: e,
        );
        
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nepodařilo se vytvořit balíček: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } finally {
        if (context.mounted) {
          isCreating.value = false;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI kartičky',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: isCreating.value ? null : createDeck,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: isCreating.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Text(
                  'Vytvořit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titul',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Zadejte název',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zadejte název balíčku';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (!showDescription.value) TextButton.icon(
                onPressed: () => showDescription.value = true,
                icon: Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  'Přidejte popis',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ) else ...[
                Text(
                  'Popis',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Zadejte popis balíčku',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  minLines: 1,
                  maxLines: null,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Vytvořit z:',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.1),
                                theme.colorScheme.primary.withOpacity(0.2),
                              ],
                              stops: [
                                animationController.value,
                                (animationController.value + 0.5) % 1.0,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return Transform.rotate(
                                    angle: animationController.value * 4 * 3.14,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withBlue(
                                        (theme.colorScheme.primary.blue + 40).clamp(0, 255),
                                      ),
                                    ],
                                    stops: [
                                      animationController.value,
                                      (animationController.value + 0.5) % 1.0,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  'Zeptat AI',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      // TODO: Implementovat PDF import
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _CardList(
                theme: theme,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () {
          final cardListNotifier = ref.read(aICardListNotifierProvider.notifier);
          cardListNotifier.addCard();
          
          // Otevřeme dialog pro novou kartičku
          final cardList = ref.read(aICardListNotifierProvider);
          showGeneralDialog<Map<String, String>>(
            context: context,
            barrierDismissible: true,
            barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
            pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
              cardIndex: cardList.length - 1,
              totalCards: cardList.length,
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _CreateFromOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final AnimationController animationController;

  const _CreateFromOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.2),
                ],
                stops: [
                  animationController.value,
                  (animationController.value + 0.5) % 1.0,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: animationController.value * 4 * 3.14,
                      child: Icon(
                        icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withBlue(
                          (theme.colorScheme.primary.blue + 40).clamp(0, 255),
                        ),
                      ],
                      stops: [
                        animationController.value,
                        (animationController.value + 0.5) % 1.0,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    label,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardInputSection extends HookConsumerWidget {
  final ThemeData theme;
  final TextEditingController frontController;
  final TextEditingController backController;
  final int index;

  const _CardInputSection({
    required this.theme,
    required this.frontController,
    required this.backController,
    required this.index,
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
    final cardList = ref.watch(aICardListNotifierProvider);
    final cardListNotifier = ref.watch(aICardListNotifierProvider.notifier);
    final cardId = cardListNotifier.getCardId(index);
    final imageData = ref.watch(cardImageNotifierProvider);

    void showAddFlashcardDialog() async {
      final result = await showGeneralDialog<Map<String, String>>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
          initialFront: cardListNotifier.getFront(index),
          initialBack: cardListNotifier.getBack(index),
          cardIndex: index,
          totalCards: cardList.length,
        ),
      );

      if (result != null) {
        cardListNotifier.updateCard(
          index,
          result['front'] ?? '',
          result['back'] ?? '',
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: imageData.when(
                      data: (images) {
                        final cardImages = images[cardId];
                        if (cardImages == null || cardImages['front'] == null) {
                          return Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cardImages['front']!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading front image: $error');
                              return Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              );
                            },
                          ),
                        );
                      },
                      loading: () => Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      error: (error, stack) {
                        print('Error loading image state: $error');
                        return Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: showAddFlashcardDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      onTap: showAddFlashcardDialog,
                      readOnly: true,
                      enabled: false,
                      controller: frontController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Období',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: imageData.when(
                      data: (images) {
                        final cardImages = images[cardId];
                        if (cardImages == null || cardImages['back'] == null) {
                          return Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cardImages['back']!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading back image: $error');
                              return Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              );
                            },
                          ),
                        );
                      },
                      loading: () => Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      error: (error, stack) {
                        print('Error loading image state: $error');
                        return Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: showAddFlashcardDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      onTap: showAddFlashcardDialog,
                      readOnly: true,
                      enabled: false,
                      controller: backController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Definice',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardList extends HookConsumerWidget {
  final ThemeData theme;

  const _CardList({
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardList = ref.watch(aICardListNotifierProvider);
    final cardListNotifier = ref.watch(aICardListNotifierProvider.notifier);

    // Vytvoříme controllery pro každou kartičku
    final controllers = useMemoized(() => List.generate(
      cardList.length,
      (index) => {
        'front': TextEditingController(text: cardListNotifier.getFront(index)),
        'back': TextEditingController(text: cardListNotifier.getBack(index)),
      },
    ), [cardList.length]);

    // Aktualizujeme text v controllerech když se změní data
    useEffect(() {
      for (var i = 0; i < cardList.length; i++) {
        controllers[i]['front']!.text = cardListNotifier.getFront(i);
        controllers[i]['back']!.text = cardListNotifier.getBack(i);
      }
      return null;
    }, [cardList]);

    // Vyčistíme controllery při dispose
    useEffect(() {
      return () {
        for (var controller in controllers) {
          controller['front']?.dispose();
          controller['back']?.dispose();
        }
      };
    }, []);

    void addNewCard() async {
      cardListNotifier.addCard();
      // Otevřeme dialog pro novou kartičku
      final result = await showGeneralDialog<Map<String, String>>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (context, animation, secondaryAnimation) => AddFlashcardDialog(
          cardIndex: cardList.length - 1,
          totalCards: cardList.length,
        ),
      );

      if (result != null) {
        cardListNotifier.updateCard(
          cardList.length - 1,
          result['front'] ?? '',
          result['back'] ?? '',
        );
      }
    }

    return Column(
      children: [
        ...List.generate(cardList.length, (index) => Column(
          children: [
            _CardInputSection(
              theme: theme,
              frontController: controllers[index]['front']!,
              backController: controllers[index]['back']!,
              index: index,
            ),
            if (index < cardList.length - 1) const SizedBox(height: 8),
            if (index < cardList.length - 1) Center(
              child: IconButton.filled(
                onPressed: addNewCard,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (index < cardList.length - 1) const SizedBox(height: 8),
          ],
        )),
        const SizedBox(height: 8),
        Center(
          child: IconButton.filled(
            onPressed: addNewCard,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
} 