import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
import 'package:kitsucode/features/auth/view/register_view.dart'; // Import the new view
import 'package:kitsucode/features/home/view/home_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      // --- NEW ROUTE ---
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      return authState.when(
        data: (data) {
          final isAuthenticated = data.session != null;
          final currentLocation = state.matchedLocation;

          // Lista de rutas que el usuario puede visitar SIN estar autenticado
          // --- UPDATED LIST ---
          final authRoutes = ['/login', '/register'];

          // ¿El usuario está en una de las rutas de autenticación?
          final isGoingToAuthRoute = authRoutes.contains(currentLocation);
          final isSplashing = currentLocation == '/splash';

          if (kDebugMode) {
            print(
              "Redirect: Auth state received. Authenticated: $isAuthenticated, Location: $currentLocation",
            );
          }

          // Desde el splash, decidimos a dónde ir
          if (isSplashing) {
            return isAuthenticated ? '/home' : '/login';
          }

          // Si el usuario está autenticado y trata de ir a login/register, llévalo a home
          if (isAuthenticated && isGoingToAuthRoute) {
            return '/home';
          }

          // Si el usuario NO está autenticado y trata de ir a una ruta protegida, llévalo a login
          if (!isAuthenticated && !isGoingToAuthRoute) {
            return '/login';
          }

          // En cualquier otro caso, no hagas nada.
          return null;
        },
        loading: () => null,
        error: (error, stackTrace) {
          if (kDebugMode) {
            print("Redirect: Auth Error: $error");
          }
          return '/login';
        },
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
