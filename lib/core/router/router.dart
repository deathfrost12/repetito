import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/screens/deck/deck_detail_screen.dart';
import '../../presentation/screens/study/study_screen.dart';
import '../../presentation/screens/statistics/study_statistics_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/library/folder_detail_screen.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/entities/folder_entity.dart';
import 'dart:developer' as developer;

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final supabase = Supabase.instance.client;

  return GoRouter(
    initialLocation: AppConstants.pathLogin,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = supabase.auth.currentUser != null;
      final isLoginRoute = state.matchedLocation == AppConstants.pathLogin;

      if (!isLoggedIn && !isLoginRoute) {
        return AppConstants.pathLogin;
      }

      if (isLoggedIn && isLoginRoute) {
        return AppConstants.pathHome;
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      supabase.auth.onAuthStateChange,
    ),
    routes: [
      GoRoute(
        path: AppConstants.pathLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.pathHome,
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: AppConstants.pathLibrary,
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppConstants.pathFolderDetail,
        name: 'folder_detail',
        builder: (context, state) {
          final folderData = state.extra;
          final folderId = state.pathParameters['id'];
          
          FolderEntity? folder;
          if (folderData is FolderEntity) {
            folder = folderData;
          } else if (folderData is Map<String, dynamic>) {
            try {
              folder = FolderEntity.fromJson(folderData);
            } catch (e, stack) {
              developer.log(
                'Error converting folder data: $e',
                name: 'Router',
                error: e,
                stackTrace: stack,
              );
            }
          }
          
          if (folder == null && folderId != null) {
            // TODO: Načíst složku podle ID
            return const MainScreen();
          }
          
          if (folder == null) {
            return const MainScreen();
          }
          
          return FolderDetailScreen(folder: folder);
        },
      ),
      GoRoute(
        path: AppConstants.pathDeckDetail,
        name: 'deck_detail',
        builder: (context, state) {
          final deck = state.extra as DeckEntity?;
          final deckId = state.pathParameters['id'];
          
          if (deck == null && deckId != null) {
            // TODO: Načíst balíček podle ID
            return const MainScreen();
          }
          
          if (deck == null) {
            return const MainScreen();
          }
          
          return DeckDetailScreen(deck: deck);
        },
      ),
      GoRoute(
        path: AppConstants.pathStudy,
        name: 'study',
        builder: (context, state) {
          final deck = state.extra as DeckEntity?;
          final deckId = state.pathParameters['deckId'];
          
          if (deck == null && deckId != null) {
            // TODO: Načíst balíček podle ID
            return const MainScreen();
          }
          
          if (deck == null) {
            return const MainScreen();
          }
          
          return StudyScreen(deck: deck);
        },
      ),
      GoRoute(
        path: AppConstants.pathStatistics,
        name: 'statistics',
        builder: (context, state) {
          final deck = state.extra as DeckEntity?;
          if (deck == null) {
            return const MainScreen();
          }
          return StudyStatisticsScreen(deck: deck);
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (_) {
        debugPrint('Auth state changed - notifying router');
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
} 