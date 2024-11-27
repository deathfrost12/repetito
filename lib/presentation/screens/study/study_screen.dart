import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/entities/card_entity.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../providers/study_progress_provider.dart';
import '../../providers/study_statistics_provider.dart';
import '../../providers/card_list_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    final cardStartTime = useState(DateTime.now());
    final sessionStats = useState({
      'totalTime': 0,
      'easyCount': 0,
      'mediumCount': 0,
      'hardCount': 0,
    });

    return dueCardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Chyba: $error')),
      data: (cards) {
        if (cards.isEmpty && !isPracticeMode.value) {
          return _buildEmptyState(context);
        }

        final displayCards = cards;
        if (currentCardIndex.value >= displayCards.length) return _buildEmptyState(context);
        final currentCard = displayCards[currentCardIndex.value];

        // Funkce pro přechod na další kartičku
        void moveToNextCard() {
          if (currentCardIndex.value + 1 >= displayCards.length) {
            _showSummaryDialog(context, sessionStats.value);
          } else {
            currentCardIndex.value++;
            isCardFlipped.value = false;
            cardStartTime.value = DateTime.now();
          }
        }

        // Funkce pro hodnocení kartičky
        Future<void> rateCard(DifficultyLevel difficulty) async {
          if (isPracticeMode.value) {
            moveToNextCard();
            return;
          }

          final studyTime = DateTime.now().difference(cardStartTime.value).inSeconds;
          
          // Aktualizovat statistiky session
          sessionStats.value = {
            'totalTime': sessionStats.value['totalTime']! + studyTime,
            'easyCount': sessionStats.value['easyCount']! + (difficulty == DifficultyLevel.easy ? 1 : 0),
            'mediumCount': sessionStats.value['mediumCount']! + (difficulty == DifficultyLevel.medium ? 1 : 0),
            'hardCount': sessionStats.value['hardCount']! + (difficulty == DifficultyLevel.hard ? 1 : 0),
          };

          // Okamžitě přejít na další kartičku
          moveToNextCard();

          // Asynchronně uložit data
          try {
            await Future.wait([
              ref.read(studyProgressProvider.notifier).updateProgress(
                cardId: currentCard.id,
                difficulty: difficulty,
                studyTimeSeconds: studyTime,
              ),
              ref.read(studyStatisticsNotifierProvider.notifier).updateStatistics(
                deckId: deck.id,
                difficulty: difficulty,
                studyTimeSeconds: studyTime,
              ),
            ]);
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
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(deck.name),
            centerTitle: true,
            actions: [
              // Progress indikátor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '${currentCardIndex.value + 1}/${displayCards.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (currentCardIndex.value + 1) / displayCards.length,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => isCardFlipped.value = !isCardFlipped.value,
                  child: _FlashCard(
                    card: currentCard,
                    isFlipped: isCardFlipped.value,
                  ),
                ),
              ),
              if (isCardFlipped.value) Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => rateCard(DifficultyLevel.easy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Snadné'),
                    ),
                    ElevatedButton(
                      onPressed: () => rateCard(DifficultyLevel.medium),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Střední'),
                    ),
                    ElevatedButton(
                      onPressed: () => rateCard(DifficultyLevel.hard),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Těžké'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
        ],
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, Map<String, int> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Souhrn studia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Celkový čas: ${_formatTime(stats['totalTime']!)}'),
            const SizedBox(height: 8),
            Text('Snadné: ${stats['easyCount']}'),
            Text('Střední: ${stats['mediumCount']}'),
            Text('Těžké: ${stats['hardCount']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/deck/${deck.id}');
            },
            child: const Text('Zpět na balíček'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
              const SizedBox(height: 16),
              Text(
                isFlipped ? 'Klepněte pro zobrazení přední strany'
                         : 'Klepněte pro zobrazení odpovědi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 