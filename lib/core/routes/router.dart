// lib/core/routes/router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports de tus vistas
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
import 'package:kitsucode/features/auth/view/register_view.dart'; // Import the new view
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/competences/view/ranking_view.dart';

// El import que tú me especificaste para usar la NavBar
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart';
// Providers
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

// Views
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart'; // Asegúrate de tener este archivo
// import 'package:kitsucode/features/home/view/home_view.dart';

// --- PLACEHOLDERS PARA LAS OTRAS PANTALLAS ---
// Reemplaza estos Widgets con tus pantallas reales cuando las crees.
class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cursos')),
    body: const Center(child: Text('Pantalla de Cursos')),
  );
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: const Center(child: Text('Pantalla de Home')),
  );
}

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Directorio')),
    body: const Center(child: Text('Pantalla de Directorio')),
  );
}

class AcademiesScreen extends StatelessWidget {
  const AcademiesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Academias')),
    body: const Center(child: Text('Pantalla de Academias')),
  );
}
// ------------------------------------------------

// Claves para mantener el estado de la navegación en cada pestaña.
final _navigatorKeys = {
  'home': GlobalKey<NavigatorState>(debugLabel: 'homeNav'),
  'courses': GlobalKey<NavigatorState>(debugLabel: 'coursesNav'),
  'directory': GlobalKey<NavigatorState>(debugLabel: 'directoryNav'),
  'academies': GlobalKey<NavigatorState>(debugLabel: 'academiesNav'),
};


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
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      // TU LÓGICA DE REDIRECCIÓN SE MANTIENE 100% IGUAL
      return authState.when(
        data: (data) {
          final isAuthenticated = data.session != null;
          final currentLocation = state.matchedLocation;

          // Lista de rutas que el usuario puede visitar SIN estar autenticado
          // --- UPDATED LIST ---
          const authRoute = '/auth';
          final isGoingToAuthRoute = currentLocation == authRoute;
          final isSplashing = currentLocation == '/splash';

          if (isSplashing) {
            return isAuthenticated ? '/home' : authRoute;
          }

          if (!isAuthenticated && !isLoggingIn) {
            return '/login';
          }

          if (isAuthenticated && isLoggingIn) {
            return '/home';
          // Si el usuario NO está autenticado y trata de ir a una ruta protegida, llévalo a login
          if (!isAuthenticated && !isGoingToAuthRoute) {
            return authRoute;
          }

          return null;
        },
        loading: () => null,
        error: (error, stackTrace) => '/login',
        error: (error, stackTrace) {
          if (kDebugMode) {
            print("Redirect: Auth Error: $error");
          }
          return '/auth';
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthView()),
      // StatefulShellRoute para manejar la navegación con BottomNavBar.
      // Esta es la ruta principal para cuando el usuario está autenticado.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Este Widget actúa como el "cascarón" que contiene la NavBar
          // y el contenido de la pestaña actual.
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Cada 'branch' es una pestaña de la barra de navegación.

          // 1. Pestaña de Inicio (Home)
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['home'],
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
                // Aquí puedes anidar sub-rutas si necesitas navegar
                // desde la pantalla de inicio a otra pantalla PERO
                // manteniendo la NavBar visible.
                // routes: [
                //   GoRoute(path: 'details', builder: ...),
                // ],
              ),
            ],
          ),

          // 2. Pestaña de Cursos (school icon)
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['courses'],
            routes: [
              GoRoute(
                path: '/courses',
                builder: (context, state) =>
                    const CoursesScreen(), // Placeholder
              ),
            ],
          ),

          // 3. Pestaña de Directorio (menu_book icon)
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['directory'],
            routes: [
              GoRoute(
                path: '/directory',
                builder: (context, state) =>
                    const DirectoryScreen(), // Placeholder
              ),
            ],
          ),

          // 4. Pestaña de Academias (collections_bookmark_sharp icon)
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['academies'],
            routes: [
              GoRoute(
                path: '/academies',
                builder: (context, state) =>
                    const AcademiesScreen(), // Placeholder
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