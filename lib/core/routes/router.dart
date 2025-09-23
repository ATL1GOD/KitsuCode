// router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
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
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
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
        loading: () {
          if (kDebugMode) {
            print("Redirect: Estado de Auth en carga...");
          }
          return null;
        },
        error: (error, stackTrace) {
          if (kDebugMode) {
            print("Redirect: Error en el estado de Auth: $error");
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
