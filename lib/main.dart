import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'core/constants/app_constants.dart';
import 'core/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: true,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: true,
      ),
    );
    
    runApp(const ProviderScope(child: RepetitoApp()));
  } catch (e, stack) {
    debugPrint('Error initializing app: $e\n$stack');
  }
}

class RepetitoApp extends HookConsumerWidget {
  const RepetitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    useEffect(() {
      final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('Auth state changed: ${data.event}');
        if (data.event == AuthChangeEvent.signedIn) {
          debugPrint('User signed in: ${data.session?.user.email}');
        }
      });

      return subscription.cancel;
    }, const []);

    return MaterialApp.router(
      title: 'Repetito',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
