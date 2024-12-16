import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/entities/card_entity.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../providers/study_progress_provider.dart';
import '../../providers/study_statistics_provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      loading: () => Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Chyba: $error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
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
                  content: Text(
                    'Chyba při ukládání: $e',
                    style: TextStyle(color: colorScheme.onError),
                  ),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          }
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: Text(
              deck.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            actions: [
              // Progress indikátor
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${currentCardIndex.value + 1}/${displayCards.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (currentCardIndex.value + 1) / displayCards.length,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => isCardFlipped.value = !isCardFlipped.value,
                  child: _FlashCard(
                    card: currentCard,
                    isFlipped: isCardFlipped.value,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
              ),
              if (isCardFlipped.value) Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DifficultyButton(
                      onPressed: () => rateCard(DifficultyLevel.easy),
                      label: 'Snadné',
                      color: const Color(0xFF4CAF50),
                      textColor: Colors.white,
                    ),
                    _DifficultyButton(
                      onPressed: () => rateCard(DifficultyLevel.medium),
                      label: 'Střední',
                      color: const Color(0xFFFF9800),
                      textColor: Colors.white,
                    ),
                    _DifficultyButton(
                      onPressed: () => rateCard(DifficultyLevel.hard),
                      label: 'Těžké',
                      color: const Color(0xFFF44336),
                      textColor: Colors.white,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Všechny kartičky jsou naučené!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vraťte se později pro další opakování',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/deck/${deck.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zpět na balíček'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, Map<String, int> stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          'Souhrn studia',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryItem(
              icon: Icons.timer,
              label: 'Celkový čas',
              value: _formatTime(stats['totalTime']!),
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _SummaryItem(
              icon: Icons.sentiment_very_satisfied,
              label: 'Snadné',
              value: '${stats['easyCount']}',
              color: const Color(0xFF4CAF50),
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _SummaryItem(
              icon: Icons.sentiment_satisfied,
              label: 'Střední',
              value: '${stats['mediumCount']}',
              color: const Color(0xFFFF9800),
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _SummaryItem(
              icon: Icons.sentiment_dissatisfied,
              label: 'Těžké',
              value: '${stats['hardCount']}',
              color: const Color(0xFFF44336),
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/deck/${deck.id}');
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _FlashCard({
    required this.card,
    required this.isFlipped,
    required this.colorScheme,
    required this.theme,
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
      child: Container(
        key: ValueKey(isFlipped),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  isFlipped ? card.backContent : card.frontContent,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Icon(
              isFlipped ? Icons.flip_to_front : Icons.flip_to_back,
              color: colorScheme.primary.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Klepněte pro ${isFlipped ? 'přední' : 'zadní'} stranu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;
  final Color textColor;

  const _DifficultyButton({
    required this.onPressed,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 