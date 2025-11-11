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

// --- VISTAS REALES ---
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/competences/view/ranking_view.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';

// --- DISTRIBUIDOR DE RETOS ---
import 'package:kitsucode/features/challenge/provider/reto_distribuidor.dart';

// --- VISTAS DE FEEDBACK ---
import 'package:kitsucode/features/challenge/view/feedback/challenge_success_view.dart';
import 'package:kitsucode/features/profile/view/all_achievements_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

// --- TUS VISTAS (dxniel7) ---
import 'package:kitsucode/features/profile/view/follow_list_view.dart';
import 'package:kitsucode/main.dart'; //

// --- VISTAS DEL EQUIPO (atl1god) ---
import 'package:kitsucode/features/desafio/view/desafio_view.dart'; // <-- FUSIÓN: Importado de la rama (atl1god)

// --- ¡NUEVAS VISTAS DE SETTINGS! ---
import 'package:kitsucode/features/settings/view/settings_view.dart';
import 'package:kitsucode/features/settings/view/notifications_view.dart';
import 'package:kitsucode/features/settings/view/support_view.dart';

// Claves (sin cambios)
final _navigatorKeys = {
  'home': GlobalKey<NavigatorState>(debugLabel: 'homeNav'),
  'ranking': GlobalKey<NavigatorState>(debugLabel: 'rankingNav'),
  // --- FUSIÓN: Cambiado 'directory' por 'desafiomensual' para que coincida con la nueva pestaña
  'desafiomensual': GlobalKey<NavigatorState>(debugLabel: 'desafioNav'),
  'profile': GlobalKey<NavigatorState>(debugLabel: 'profileNav'),
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      // ... Lógica de redirección (sin cambios) ...
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
        path: '/reto/:retoId/:nivelId', // ← ¡MODIFICADO!
        builder: (context, state) {
          final retoId = state.pathParameters['retoId']!;
          final nivelId = state.pathParameters['nivelId']!; // ← ¡AÑADIDO!
          return RetoDistribuidorPage(
            retoId: retoId,
            nivelId: nivelId, // ← ¡AÑADIDO!
          );
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

      // --- ¡NUEVAS RUTAS DE SETTINGS AÑADIDAS! ---
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
        routes: [
          // Sub-rutas de settings
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsView(),
            // Aquí podrías anidar más rutas si quisieras:
            // routes: [
            //   GoRoute(path: 'recordatorios', ...),
            //   GoRoute(path: 'amigos', ...),
            // ]
          ),
          GoRoute(
            path: 'support',
            builder: (context, state) => const SupportView(),
          ),
        ],
      ),
      // --- FIN DE NUEVAS RUTAS ---

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
          final List<RecursoModel> recursos =
              (state.extra is List<RecursoModel>)
              ? state.extra as List<RecursoModel>
              : <RecursoModel>[];
          return ChallengeFailureView(recursos: recursos);
        },
      ),

      // --- FUSIÓN: Se usa TUS rutas de perfil anidadas (dxniel7) ---
      // Son más completas que las del equipo.
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
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
                return const Scaffold(
                  body: Center(child: Text("Error: Tipo de lista inválido")),
                );
              }

              return FollowListView(userId: userId, type: type);
            },
          ),
        ],
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

          // 3️⃣ --- FUSIÓN: Se usa la nueva pestaña del equipo (atl1god) ---
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['desafiomensual'],
            routes: [
              GoRoute(
                path: '/desafiomensual', // <-- Nueva ruta
                builder: (context, state) =>
                    const DesafiosView(), // <-- Nueva vista
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
                  // Esta ruta es para que /profile/un-id-especifico
                  // también funcione DENTRO de la pestaña de perfil.
                  // La versión /profile/:userId de arriba es para links EXTERNOS.
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
    // --- FUSIÓN: Se usa tu observer (dxniel7) ---
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