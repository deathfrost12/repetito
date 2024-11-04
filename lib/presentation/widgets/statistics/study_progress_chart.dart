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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rozložení obtížnosti',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 2,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: statistics.easyCount.toDouble(),
                      title: 'Snadné\n${statistics.easyCount}',
                      color: Colors.green,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: statistics.mediumCount.toDouble(),
                      title: 'Střední\n${statistics.mediumCount}',
                      color: Colors.orange,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: statistics.hardCount.toDouble(),
                      title: 'Těžké\n${statistics.hardCount}',
                      color: Colors.red,
                      radius: 100,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 