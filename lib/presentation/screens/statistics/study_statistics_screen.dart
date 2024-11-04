import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../providers/study_statistics_provider.dart';
import '../../widgets/statistics/study_progress_chart.dart';

class StudyStatisticsScreen extends HookConsumerWidget {
  final DeckEntity deck;

  const StudyStatisticsScreen({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(studyStatisticsProvider(deck.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiky studia'),
        centerTitle: true,
      ),
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Chyba: $error')),
        data: (statistics) {
          if (statistics == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Zatím nemáte žádné statistiky',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Statistiky se zobrazí po procvičení kartiček',
                    style: TextStyle(
                      color: Colors.grey,
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
                  child: Column(
                    children: [
                      _StatisticRow(
                        icon: Icons.timer,
                        label: 'Celkový čas studia',
                        value: statistics.formattedStudyTime,
                      ),
                      const Divider(),
                      _StatisticRow(
                        icon: Icons.school,
                        label: 'Naučené kartičky',
                        value: '${statistics.totalCardsStudied}',
                      ),
                      const Divider(),
                      _StatisticRow(
                        icon: Icons.trending_up,
                        label: 'Průměrná obtížnost',
                        value: '${statistics.averageDifficulty.toStringAsFixed(1)}/3.0',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StudyProgressChart(statistics: statistics),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Hodnocení kartiček',
                  child: Column(
                    children: [
                      _DifficultyBar(
                        label: 'Snadné',
                        count: statistics.easyCount,
                        total: statistics.totalCardsStudied,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _DifficultyBar(
                        label: 'Střední',
                        count: statistics.mediumCount,
                        total: statistics.totalCardsStudied,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _DifficultyBar(
                        label: 'Těžké',
                        count: statistics.hardCount,
                        total: statistics.totalCardsStudied,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Streak',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        '${statistics.streakDays} dní',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
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

  const _StatisticsCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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

  const _StatisticRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
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
            Text(label),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
} 