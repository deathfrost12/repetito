import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/entities/study_statistics_entity.dart';

class StudyProgressChart extends StatelessWidget {
  final StudyStatisticsEntity statistics;

  const StudyProgressChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rozložení obtížnosti',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: statistics.easyCount.toDouble(),
                      title: 'Snadné\n${statistics.easyCount}',
                      color: const Color(0xFF4CAF50),
                      radius: 80,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      showTitle: statistics.easyCount > 0,
                    ),
                    PieChartSectionData(
                      value: statistics.mediumCount.toDouble(),
                      title: 'Střední\n${statistics.mediumCount}',
                      color: const Color(0xFFFF9800),
                      radius: 80,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      showTitle: statistics.mediumCount > 0,
                    ),
                    PieChartSectionData(
                      value: statistics.hardCount.toDouble(),
                      title: 'Těžké\n${statistics.hardCount}',
                      color: const Color(0xFFF44336),
                      radius: 80,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      showTitle: statistics.hardCount > 0,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: 180,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(
                  color: const Color(0xFF4CAF50),
                  label: 'Snadné',
                  value: statistics.easyCount,
                  theme: theme,
                ),
                _LegendItem(
                  color: const Color(0xFFFF9800),
                  label: 'Střední',
                  value: statistics.mediumCount,
                  theme: theme,
                ),
                _LegendItem(
                  color: const Color(0xFFF44336),
                  label: 'Těžké',
                  value: statistics.hardCount,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final ThemeData theme;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($value)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
} 