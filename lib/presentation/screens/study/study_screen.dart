import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/entities/card_entity.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../providers/study_progress_provider.dart';
import '../../providers/card_list_provider.dart';
import 'package:go_router/go_router.dart';

class StudyScreen extends HookConsumerWidget {
  final DeckEntity deck;

  const StudyScreen({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCardsAsync = ref.watch(dueCardsProvider(deck.id));
    final isCardFlipped = useState(false);
    final currentCardIndex = useState(0);
    final isPracticeMode = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        centerTitle: true,
      ),
      body: dueCardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Chyba: $error')),
        data: (cards) {
          if (cards.isEmpty && !isPracticeMode.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Všechny kartičky jsou naučené!',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Další kartičky budou k dispozici později',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/deck/${deck.id}'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zpět na balíček'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          isPracticeMode.value = true;
                        },
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Practice Mode'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final allCards = ref.watch(practiceCardsProvider(deck.id));
          final displayCards = isPracticeMode.value 
              ? allCards.value ?? []
              : cards;

          if (currentCardIndex.value >= displayCards.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPracticeMode.value ? Icons.fitness_center : Icons.celebration,
                    size: 64,
                    color: isPracticeMode.value ? Colors.blue : Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPracticeMode.value 
                        ? 'Dokončili jste procvičování!'
                        : 'Dokončili jste studium!',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPracticeMode.value
                        ? 'Chcete procvičovat znovu?'
                        : 'Další kartičky budou k dispozici podle vašeho hodnocení',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/deck/${deck.id}'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zpět na balíček'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          currentCardIndex.value = 0;
                          isCardFlipped.value = false;
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Začít znovu'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final currentCard = displayCards[currentCardIndex.value];
          final progress = (currentCardIndex.value + 1) / displayCards.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    isCardFlipped.value = !isCardFlipped.value;
                  },
                  child: _FlashCard(
                    card: currentCard,
                    isFlipped: isCardFlipped.value,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Kartička ${currentCardIndex.value + 1} z ${displayCards.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!isCardFlipped.value) ...[
                      FilledButton(
                        onPressed: () {
                          isCardFlipped.value = true;
                        },
                        child: const Text('Ukázat odpověď'),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: DifficultyLevel.values.map((difficulty) {
                          return ElevatedButton(
                            onPressed: () async {
                              try {
                                if (!isPracticeMode.value) {
                                  await ref.read(studyProgressProvider.notifier).updateProgress(
                                    cardId: currentCard.id,
                                    difficulty: difficulty,
                                  );
                                }
                                
                                await Future.delayed(const Duration(milliseconds: 300));
                                
                                if (context.mounted) {
                                  currentCardIndex.value++;
                                  isCardFlipped.value = false;
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Chyba při ukládání: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: difficulty.color.withOpacity(0.1),
                              foregroundColor: difficulty.color,
                            ),
                            child: Text(difficulty.label),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final CardEntity card;
  final bool isFlipped;

  const _FlashCard({
    required this.card,
    required this.isFlipped,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Card(
        key: ValueKey(isFlipped),
        margin: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFlipped ? card.backContent : card.frontContent,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (isFlipped) ...[
                const SizedBox(height: 16),
                Text(
                  'Klepněte pro zobrazení přední strany',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Klepněte pro zobrazení odpovědi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 