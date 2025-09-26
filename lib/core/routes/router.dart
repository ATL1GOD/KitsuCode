// router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/login_view.dart';
import 'package:kitsucode/features/home/view/home_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/view/profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_profile_view.dart';
import 'package:kitsucode/features/profile/view/edit_avatar_view.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Observa el estado de autenticación de forma asíncrona
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    //initialLocation: '/profile', --lo puse porque no tenia la BD
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileView()),
      GoRoute(
    path: '/edit-profile',
    builder: (context, state) {
      // Recibimos el objeto userProfile que pasamos como argumento
      final userProfile = state.extra as UserProfileModel;
      return EditProfileView(userProfile: userProfile);
    },
  ),  
  GoRoute(
        path: '/edit-avatar',
        builder: (context, state) {
          // Recibimos el avatar actual como argumento
          final currentAvatar = state.extra as String?  ?? 'assets/images/login_zorro.png';
          return EditAvatarView(currentAvatar: currentAvatar);
        },
      ),
     GoRoute(
        path: '/all-stats',
        builder: (context, state) => const AllStatsView(),
      ),
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
            return isAuthenticated ? '/profile' : '/login';
          }

          // Si el usuario no está autenticado y no está en la página de login, redirigir a login.
          if (!isAuthenticated && !isLoggingIn) {
            return '/login';
          }

          // Si el usuario está autenticado y está en la página de login, redirigir a profile.
          if (isAuthenticated && isLoggingIn) {
            return '/profile';
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
      return null;
    },
    // Refresca el estado del router cuando cambie el estado de autenticación.
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
