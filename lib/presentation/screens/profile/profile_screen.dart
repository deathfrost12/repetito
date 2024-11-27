import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repetito/core/router/router.dart';
import 'package:repetito/presentation/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final user = Supabase.instance.client.auth.currentUser;

    String getThemeModeText(ThemeMode? mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Světlý režim';
        case ThemeMode.dark:
          return 'Tmavý režim';
        case ThemeMode.system:
          return 'Systémový režim';
        default:
          return 'Systémový režim';
      }
    }

    IconData getThemeModeIcon(ThemeMode? mode) {
      switch (mode) {
        case ThemeMode.light:
          return Icons.light_mode;
        case ThemeMode.dark:
          return Icons.dark_mode;
        case ThemeMode.system:
          return Icons.settings_brightness;
        default:
          return Icons.settings_brightness;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          if (user?.userMetadata?['avatar_url'] != null)
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  user!.userMetadata!['avatar_url'] as String,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (user?.userMetadata?['full_name'] != null)
            Center(
              child: Text(
                user!.userMetadata!['full_name'] as String,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          if (user?.email != null)
            Center(
              child: Text(
                user!.email!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      getThemeModeIcon(themeMode.value),
                    ),
                    title: const Text('Vzhled aplikace'),
                    subtitle: Text(getThemeModeText(themeMode.value)),
                    onTap: () {
                      ref.read(themeNotifierProvider.notifier).toggleTheme();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Odhlásit se'),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
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
} 