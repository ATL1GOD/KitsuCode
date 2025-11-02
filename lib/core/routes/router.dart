// lib/core/routes/router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports de tus vistas
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/competences/view/ranking_view.dart';
import 'package:kitsucode/features/profile/view/all_achievements_view.dart';

// El import que tú me especificaste para usar la NavBar
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart';


// Clave global para el navegador raíz.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
 
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // --- RUTAS SIN NAVBAR ---
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileView()),
      GoRoute(
        path: '/edit-avatar',
        builder: (context, state) {
          final currentAvatar = state.extra as String? ?? 'assets/images/login_zorro.png';
          return EditAvatarView(currentAvatar: currentAvatar);
        },
      ),
      GoRoute(path: '/all-stats', builder: (context, state) => const AllStatsView()),
      GoRoute(
  path: '/profile/:userId/achievements',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return AllAchievementsView(userId: userId);
  },
),

      // --- ESTRUCTURA DE LA NAVBAR ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Pestaña 0: Home 
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeView()),
            ],
          ),

          // Pestaña 1: Ranking 
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ranking', builder: (context, state) => const RankingView()),
            ],
          ),

          // Pestaña 2: Social (INACTIVA PERO SIN ERROR)
          StatefulShellBranch(
            // aun no tiene nada jaja
            routes: [
              GoRoute(
                path: '/social_placeholder', 
                builder: (context, state) => const SizedBox.shrink()),
            ],
          ),

          // Pestaña 3: Perfil 
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
                routes: [
                  GoRoute(
                    path: ':userId',
                    builder: (context, state) => ProfileView(userId: state.pathParameters['userId']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // TU LÓGICA DE REDIRECCIÓN SE MANTIENE 100% IGUAL
      return authState.when(
        data: (data) {
          final isAuthenticated = data.session != null;
          final isLoggingIn = state.matchedLocation == '/login';
          final isSplashing = state.matchedLocation == '/splash';

          if (isSplashing) {
            return isAuthenticated ? '/home' : '/login';
          }

          if (!isAuthenticated && !isLoggingIn) {
            return '/login';
          }

          if (isAuthenticated && isLoggingIn) {
            return '/home';
          }

          return null;
        },
        loading: () => null,
        error: (error, stackTrace) => '/login',
      );
    },
    refreshListenable: GoRouterRefreshStream(ref),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    notifyListeners();
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}