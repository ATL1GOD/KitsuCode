// [COMIENZO DEL ARCHIVO router.dart]
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

// Views
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart';

// --- TUS VISTAS REALES ---
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/competences/view/ranking_view.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';

// --- ¡NUEVO! IMPORTAR EL DISTRIBUIDOR DE RETOS ---
// (La ruta puede variar según donde lo guardes)
import 'package:kitsucode/features/challenge/provider/reto_distribuidor.dart';
import 'package:kitsucode/features/desafio/view/desafio_view.dart';

// Claves (sin cambios)
final _navigatorKeys = {
  'home': GlobalKey<NavigatorState>(debugLabel: 'homeNav'),
  'ranking': GlobalKey<NavigatorState>(debugLabel: 'rankingNav'),
  'directory': GlobalKey<NavigatorState>(debugLabel: 'directoryNav'),
  'profile': GlobalKey<NavigatorState>(debugLabel: 'profileNav'),
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      // ... Tu lógica de redirección (sin cambios) ...
      return authState.when(
        data: (data) {
          final isAuthenticated = data.session != null;
          final currentLocation = state.matchedLocation;

          const authRoute = '/auth';
          final isGoingToAuthRoute = currentLocation == authRoute;
          final isSplashing = currentLocation == '/splash';

          if (kDebugMode) {
            print(
              "Redirect: Auth state received. Authenticated: $isAuthenticated, Location: $currentLocation",
            );
          }

          if (isSplashing) {
            return isAuthenticated ? '/home' : authRoute;
          }
          if (isAuthenticated && isGoingToAuthRoute) {
            return '/home';
          }
          if (!isAuthenticated && !isGoingToAuthRoute) {
            return authRoute;
          }
          return null;
        },
        loading: () => null,
        error: (error, stackTrace) {
          if (kDebugMode) {
            print("Redirect: Auth Error: $error");
          }
          return '/auth';
        },
      );
    },
    routes: [
      // --- Splash screen (sin cambios) ---
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      // --- Ruta pública de autenticación (sin cambios) ---
      GoRoute(path: '/auth', builder: (context, state) => const AuthView()),

      // --- Rutas internas (ya autenticado) ---

      // --- ¡RUTA ÚNICA DE RETOS! (MODIFICADO) ---
      GoRoute(
        path: '/reto/:retoId', // <-- RUTA GENERAL
        builder: (context, state) {
          final retoId = state.pathParameters['retoId']!;
          // Apunta a tu nuevo distribuidor
          return RetoDistribuidorPage(retoId: retoId);
        },
      ),

      // --- (Se borran las rutas /quiz-loader, /puzzle-loader, etc.) ---
      // --- Fin de rutas de retos ---
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileView(),
      ),
      GoRoute(
        path: '/edit-avatar',
        builder: (context, state) {
          // ... (sin cambios)
          final currentAvatar =
              state.extra as String? ?? 'assets/images/login_zorro.png';
          return EditAvatarView(currentAvatar: currentAvatar);
        },
      ),
      GoRoute(
        path: '/all-stats',
        builder: (context, state) => const AllStatsView(),
      ),

      // --- NAVBAR PRINCIPAL (sin cambios) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // ... (Tus 4 branches de navbar: home, ranking, directory, profile sin cambios) ...
          // 1️⃣ HOME
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['home'],
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),

          // 2️⃣ RANKING
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['ranking'],
            routes: [
              GoRoute(
                path: '/ranking',
                builder: (context, state) => const RankingView(),
              ),
            ],
          ),

          // 3️⃣ DIRECTORIO
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['directory'],
            routes: [
              GoRoute(
                path: '/desafio',
                builder: (context, state) => const DesafiosView(),
              ),
            ],
          ),

          // 4️⃣ PERFIL
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['profile'],
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
                routes: [
                  GoRoute(
                    path: ':userId',
                    builder: (context, state) =>
                        ProfileView(userId: state.pathParameters['userId']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// (Sin cambios)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    notifyListeners();
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
// [FIN DEL ARCHIVO router.dart]