import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/study_statistics_provider.dart';
import '../../providers/deck_list_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final statisticsAsync = ref.watch(userStatisticsProvider);
    final decksAsync = ref.watch(deckListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Profil'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Odhlásit se?'),
                      content: const Text('Opravdu se chcete odhlásit?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Zrušit'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Odhlásit'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await Supabase.instance.client.auth.signOut();
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil uživatele
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: user?.userMetadata?['avatar_url'] != null
                                ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                                : null,
                            child: user?.userMetadata?['avatar_url'] == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.userMetadata?['full_name'] as String? ?? 'Uživatel',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Celkové statistiky
                  statisticsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Chyba: $error')),
                    data: (statistics) {
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Celkové statistiky',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _StatRow(
                                    icon: Icons.timer,
                                    label: 'Celkový čas studia',
                                    value: _formatStudyTime(totalStudyTime),
                                  ),
                                  const Divider(),
                                  _StatRow(
                                    icon: Icons.school,
                                    label: 'Naučené kartičky',
                                    value: '$totalCardsStudied',
                                  ),
                                  const Divider(),
                                  _StatRow(
                                    icon: Icons.library_books,
                                    label: 'Počet balíčků',
                                    value: '${statistics.length}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
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