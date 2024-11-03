import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přihlášení'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final response = await Supabase.instance.client.auth.signInWithOAuth(
                    OAuthProvider.google,
                    redirectTo: AppConstants.deepLinkRedirectUri,
                    queryParams: {
                      'access_type': 'offline',
                      'prompt': 'consent',
                    },
                    authScreenLaunchMode: LaunchMode.externalApplication,
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Zavře dialog s načítáním
                  }

                  if (!response) {
                    throw Exception('Přihlášení selhalo');
                  }

                  debugPrint('OAuth response: $response');
                  
                  if (context.mounted) {
                    context.go(AppConstants.pathHome);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Zavře dialog s načítáním
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chyba přihlášení: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Přihlásit se přes Google'),
            ),
          ],
        ),
      ),
    );
  }
} 