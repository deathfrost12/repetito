import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../widgets/statistics/study_progress_chart.dart';
import '../../providers/study_statistics_provider.dart';

class StudyStatisticsScreen extends HookConsumerWidget {
  final DeckEntity deck;

  const StudyStatisticsScreen({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statisticsAsync = ref.watch(studyStatisticsProvider(deck.id));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Statistiky studia',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: statisticsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Chyba: $error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (statistics) {
          if (statistics == null) {
            return Center(
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
                      Icons.bar_chart,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Zatím nemáte žádné statistiky',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Statistiky se zobrazí po procvičení kartiček',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatisticsCard(
                  title: 'Celkový přehled',
                  colorScheme: colorScheme,
                  theme: theme,
                  child: Column(
                    children: [
                      _StatisticRow(
                        icon: Icons.timer,
                        label: 'Celkový čas studia',
                        value: statistics.formattedStudyTime,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      Divider(color: colorScheme.outline.withOpacity(0.2)),
                      _StatisticRow(
                        icon: Icons.school,
                        label: 'Naučené kartičky',
                        value: '${statistics.totalCardsStudied}',
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      Divider(color: colorScheme.outline.withOpacity(0.2)),
                      _StatisticRow(
                        icon: Icons.trending_up,
                        label: 'Průměrná obtížnost',
                        value: '${statistics.averageDifficulty.toStringAsFixed(1)}/3.0',
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StudyProgressChart(statistics: statistics),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Hodnocení kartiček',
                  colorScheme: colorScheme,
                  theme: theme,
                  child: Column(
                    children: [
                      _DifficultyBar(
                        label: 'Snadné',
                        count: statistics.easyCount,
                        total: statistics.totalCardsStudied,
                        color: const Color(0xFF4CAF50),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Střední',
                        count: statistics.mediumCount,
                        total: statistics.totalCardsStudied,
                        color: const Color(0xFFFF9800),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _DifficultyBar(
                        label: 'Těžké',
                        count: statistics.hardCount,
                        total: statistics.totalCardsStudied,
                        color: const Color(0xFFF44336),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Streak',
                  colorScheme: colorScheme,
                  theme: theme,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Color(0xFFFF9800),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${statistics.streakDays} dní',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

class _StatisticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _StatisticsCard({
    required this.title,
    required this.child,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _StatisticRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
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
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 