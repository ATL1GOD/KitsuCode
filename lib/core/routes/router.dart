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

// --- IMPORTAR EL DISTRIBUIDOR DE RETOS ---
import 'package:kitsucode/features/challenge/provider/reto_distribuidor.dart';
import 'package:kitsucode/features/desafio/view/desafio_view.dart';

import 'package:kitsucode/features/challenge/view/feedback/challenge_success_view.dart';
import 'package:kitsucode/features/profile/view/all_achievements_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;
import 'package:kitsucode/features/profile/view/follow_list_view.dart';
import 'package:kitsucode/main.dart'; // importar el observer


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
      // --- Rutas de Nivel Superior (sin cambios) ---
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      GoRoute(path: '/auth', builder: (context, state) => const AuthView()),

      GoRoute(
        path: '/reto/:retoId', // RUTA GENERAL
        builder: (context, state) {
          final retoId = state.pathParameters['retoId']!;
          return RetoDistribuidorPage(retoId: retoId);
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
      
      GoRoute(path: '/all-stats', builder: (context, state) => const AllStatsView()),

      // --- RUTA PARA FEEDBACK DE ÉXITO (sin cambios) ---
      GoRoute(
        path: '/challenge_success',
        name: 'challenge_success',
        builder: (context, state) {
          final int trofeos = (state.extra is int) ? state.extra as int : 0;
          return ChallengeSuccessView(trofeosObtenidos: trofeos);
        },
      ),

      // --- RUTA PARA FEEDBACK DE FRACASO (sin cambios) ---
      GoRoute(
        path: '/challenge_failure',
        name: 'challenge_failure',
        builder: (context, state) {
          final List<RecursoModel> recursos = (state.extra is List<RecursoModel>) 
              ? state.extra as List<RecursoModel>
              : <RecursoModel>[]; 
          return ChallengeFailureView(recursos: recursos);
        },
      ),
      
      // ✅ RUTA CONSOLIDADA PARA PERFILES EXTERNOS Y DETALLES
      // Esta ruta manejará tanto /profile/:userId como todas sus sub-rutas detalladas.
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          // Por defecto, muestra la vista de perfil de otro usuario
          return ProfileView(userId: userId); 
        },
        routes: [
          // ✅ RUTA ANIDADA 1: /profile/:userId/achievements
          GoRoute(
            path: 'achievements',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return AllAchievementsView(userId: userId);
            },
          ),
          
          // ✅ RUTA ANIDADA 2: /profile/:userId/follow/:type
          GoRoute(
            path: 'follow/:type', // 'following' o 'followers'
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              final type = state.pathParameters['type']!;

              if (type != 'following' && type != 'followers') {
                return const Scaffold(body: Center(child: Text("Error: Tipo de lista inválido")));
              }

              return FollowListView(
                userId: userId,
                type: type,
              );
            },
          ),
        ],
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
            navigatorKey: _navigatorKeys['desafiomensual'],
            routes: [
              GoRoute(
                path: '/desafios',
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
    observers: [routeObserver],
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