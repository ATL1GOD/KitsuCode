import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

// Views
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart'; // Asegúrate de tener este archivo

// --- TUS VISTAS REALES ---
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/competences/view/ranking_view.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
// IMPORTAR EL CARGADOR DEL QUIZ
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';
// ------------------------------------------------

// Claves para mantener el estado de la navegación en cada pestaña.
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

          // Desde el splash, decidimos a dónde ir
          if (isSplashing) {
            return isAuthenticated ? '/home' : authRoute;
          }

          // Si el usuario está autenticado y trata de ir a login/register, llévalo a home
          if (isAuthenticated && isGoingToAuthRoute) {
            return '/home';
          }

          // Si el usuario NO está autenticado y trata de ir a una ruta protegida, llévalo a login
          if (!isAuthenticated && !isGoingToAuthRoute) {
            return authRoute;
          }

          // En cualquier otro caso, no hagas nada.
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
      // --- Splash screen ---
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      // --- Ruta pública de autenticación ---
      GoRoute(path: '/auth', builder: (context, state) => const AuthView()),

      // --- Rutas internas (ya autenticado) ---
      // AÑADIR LA RUTA DEL QUIZ LOADER AQUÍ
      GoRoute(
        path: '/quiz-loader/:seccionId',
        builder: (context, state) {
          final seccionId = state.pathParameters['seccionId']!;
          return QuizLoaderPage(seccionId: seccionId);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileView(),
      ),
      GoRoute(
        path: '/edit-avatar',
        builder: (context, state) {
          final currentAvatar =
              state.extra as String? ?? 'assets/images/login_zorro.png';
          return EditAvatarView(currentAvatar: currentAvatar);
        },
      ),
      GoRoute(
        path: '/all-stats',
        builder: (context, state) => const AllStatsView(),
      ),

      // --- NAVBAR PRINCIPAL ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
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

          // 3️⃣ DIRECTORIO (puedes usar para otra sección futura)
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['directory'],
            routes: [
              GoRoute(
                path: '/directory',
                builder: (context, state) => const Scaffold(
                  body: Center(
                    child: Text('Pantalla de Directorio (placeholder)'),
                  ),
                ),
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    notifyListeners();
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
