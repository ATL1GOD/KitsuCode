// router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
import 'package:kitsucode/features/home/view/home_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Observa el estado de autenticación de forma asíncrona
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
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Usamos .when para manejar todos los casos del stream de forma segura
      return authState.when(
        data: (data) {
          final isAuthenticated = data.session != null;
          final isLoggingIn = state.matchedLocation == '/login';
          final isSplashing = state.matchedLocation == '/splash';

          if (kDebugMode) {
            print(
              "Redirect: Estado de Auth recibido. Autenticado: $isAuthenticated, Ubicación actual: ${state.matchedLocation}",
            );
          }

          // Si estamos en la splash screen, decidimos a dónde ir.
          if (isSplashing) {
            return isAuthenticated ? '/home' : '/login';
          }

          // Si el usuario no está autenticado y no está en la página de login, redirigir a login.
          if (!isAuthenticated && !isLoggingIn) {
            return '/login';
          }

          // Si el usuario está autenticado y está en la página de login, redirigir a home.
          if (isAuthenticated && isLoggingIn) {
            return '/home';
          }

          // En cualquier otro caso, no redirigir.
          return null;
        },
        // MIENTRAS CARGA, no hagas nada. Quédate en la splash screen.
        loading: () {
          if (kDebugMode) {
            print("Redirect: Estado de Auth en carga...");
          }
          return null; // Devuelve null para permanecer en la ruta actual (/splash)
        },
        // SI HAY UN ERROR, llévalo a la pantalla de login para que lo intente de nuevo.
        error: (error, stackTrace) {
          if (kDebugMode) {
            print("Redirect: Error en el estado de Auth: $error");
          }
          return '/login';
        },
      );
    },
    // Refresca el estado del router cuando cambie el estado de autenticación.
    refreshListenable: GoRouterRefreshStream(ref),
  );
});

// La clase GoRouterRefreshStream no necesita cambios.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    notifyListeners();
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
