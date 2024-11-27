import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../domain/entities/study_statistics_entity.dart';
import '../../providers/study_statistics_provider.dart';
import '../../providers/deck_list_provider.dart';

class UserStatisticsScreen extends HookConsumerWidget {
  const UserStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(userStatisticsProvider);
    final decksAsync = ref.watch(deckListProvider);

    return Scaffold(
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Chyba: $error')),
        data: (statistics) {
          if (statistics.isEmpty) {
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

          // Celkové statistiky
          int totalCardsStudied = 0;
          int totalStudyTime = 0;
          int totalEasy = 0;
          int totalMedium = 0;
          int totalHard = 0;

          for (var stat in statistics.values) {
            totalCardsStudied += stat.totalCardsStudied;
            totalStudyTime += stat.totalStudyTimeSeconds;
            totalEasy += stat.easyCount;
            totalMedium += stat.mediumCount;
            totalHard += stat.hardCount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Celkové statistiky',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Přehled studia',
                  child: Column(
                    children: [
                      _StatisticRow(
                        icon: Icons.timer,
                        label: 'Celkový čas studia',
                        value: _formatStudyTime(totalStudyTime),
                      ),
                      const Divider(),
                      _StatisticRow(
                        icon: Icons.school,
                        label: 'Naučené kartičky',
                        value: '$totalCardsStudied',
                      ),
                      const Divider(),
                      _StatisticRow(
                        icon: Icons.trending_up,
                        label: 'Průměrná úspěšnost',
                        value: '${_calculateMasteryPercentage(totalEasy, totalMedium, totalHard).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StatisticsCard(
                  title: 'Hodnocení kartiček',
                  child: Column(
                    children: [
                      _DifficultyBar(
                        label: 'Snadné',
                        count: totalEasy,
                        total: totalCardsStudied,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _DifficultyBar(
                        label: 'Střední',
                        count: totalMedium,
                        total: totalCardsStudied,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _DifficultyBar(
                        label: 'Těžké',
                        count: totalHard,
                        total: totalCardsStudied,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Statistiky podle balíčků',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                decksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Chyba: $error')),
                  data: (decks) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      final deckStats = statistics[deck.id];
                      
                      if (deckStats == null) return const SizedBox.shrink();

                      return Card(
                        child: ListTile(
                          title: Text(deck.name),
                          subtitle: Text(
                            'Naučeno: ${deckStats.totalCardsStudied} kartiček\n'
                            'Čas studia: ${_formatStudyTime(deckStats.totalStudyTimeSeconds)}',
                          ),
                          trailing: CircularProgressIndicator(
                            value: deckStats.masteryPercentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  double _calculateMasteryPercentage(int easy, int medium, int hard) {
    final total = easy + medium + hard;
    if (total == 0) return 0;
    return (easy / total) * 100;
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