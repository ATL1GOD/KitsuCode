// [COMIENZO DEL ARCHIVO router.dart]
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- ¡IMPORTADO!

// Providers
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_resetpassword.dart';
// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:kitsucode/features/auth/view/widgets/auth_update_password.dart';

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

// --- TUS VISTAS (dxniel7) ---
import 'package:kitsucode/features/profile/view/follow_list_view.dart';
import 'package:kitsucode/main.dart';

// --- VISTAS DEL EQUIPO (atl1god) ---
import 'package:kitsucode/features/desafio/view/desafio_view.dart';

// --- VISTAS DE SETTINGS ---
import 'package:kitsucode/features/settings/view/settings_view.dart';
import 'package:kitsucode/features/settings/view/notifications_view.dart';
import 'package:kitsucode/features/settings/view/support_view.dart';
import 'package:kitsucode/features/settings/view/study_reminder_view.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/settings/view/widgets/notification_category_view.dart';
import 'package:kitsucode/features/profile/view/challenge_history_view.dart';
import 'package:kitsucode/features/settings/view/change_password_view.dart';
import 'package:kitsucode/features/splash/view/splash_view.dart';

// 🎉 NUEVO: Vista de celebración de lenguaje completado
import 'package:kitsucode/features/challenge/view/language_completion_flow.dart';

// 🔥 Conectividad
import 'package:kitsucode/core/providers/connectivity_provider.dart';
import 'package:kitsucode/core/widgets/no_internet_view.dart';

// Claves
final _navigatorKeys = {
  'home': GlobalKey<NavigatorState>(debugLabel: 'homeNav'),
  'ranking': GlobalKey<NavigatorState>(debugLabel: 'rankingNav'),
  'desafiomensual': GlobalKey<NavigatorState>(debugLabel: 'desafioNav'),
  'profile': GlobalKey<NavigatorState>(debugLabel: 'profileNav'),
};

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),

    // --- ### LÓGICA DE REDIRECT CORREGIDA ### ---
    redirect: (context, state) {
      final isLogged = ref.read(authStateProvider).valueOrNull?.session != null;
      final loc = state.matchedLocation;

      // Definir rutas públicas/de autenticación
      final inAuthRoute =
          loc == '/auth' ||
          loc == '/forgot-password' ||
          loc == '/update-password';
      final inSplash = loc == '/';
      final inNoInternet = loc == '/no-internet';

      // 1. Siempre permitir la ruta de "sin internet"
      if (inNoInternet) return null;

      // 2. Permitir siempre la pantalla de actualizar contraseña (para el flujo de reseteo)
      if (loc == '/update-password') return null;

      // 3. Lógica del Splash (¡LA CORRECCIÓN!)
      if (inSplash) {
        // Si estamos en el Splash Y acabamos de iniciar sesión (ej. Google),
        // ¡sácalo de ahí y llévalo al home!
        if (isLogged) return '/home';

        // Si no, quédate en el Splash (está cargando)
        return null;
      }

      // 4. Lógica de Rutas de Auth (Login, Registro, etc.)
      if (inAuthRoute) {
        // Si ya está logueado y visita /auth, llévalo al home
        if (isLogged) return '/home';

        // Si no, déjalo en la ruta de auth
        return null;
      }

      // 5. Lógica de Rutas Protegidas (todas las demás)
      if (!isLogged) {
        // Si no está logueado y no está en una ruta de auth,
        // mándalo a /auth
        return '/auth';
      }

      // 6. Si está logueado y en una ruta protegida, déjalo estar
      return null;
    },
    routes: [
      // Splash
      GoRoute(path: '/', builder: (context, state) => const SplashView()),

      // Auth
      GoRoute(path: '/auth', builder: (context, state) => const AuthView()),

      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),

      // --- ¡NUEVA RUTA AÑADIDA! ---
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordView(),
      ),

      // 🔥 NUEVA RUTA: Vista de sin internet
      GoRoute(
        path: '/no-internet',
        builder: (context, state) => const NoInternetView(),
      ),

      // Reto
      GoRoute(
        path: '/reto/:retoId/:nivelId',
        builder: (context, state) {
          final retoId = state.pathParameters['retoId']!;
          final nivelId = state.pathParameters['nivelId']!;
          return RetoDistribuidorPage(retoId: retoId, nivelId: nivelId);
        },
      ),

      // Perfil
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileView(),
      ),

      GoRoute(
        path: '/edit-avatar',
        builder: (context, state) {
          final currentAvatarId = state.extra as int? ?? 1;
          return EditAvatarView(currentAvatarId: currentAvatarId);
        },
      ),

      GoRoute(
        path: '/all-stats',
        builder: (context, state) => const AllStatsView(),
      ),

      // --- RUTA DE SETTINGS
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsView(),
            routes: [
              GoRoute(
                path: 'reminder',
                builder: (context, state) {
                  final setting = state.extra as NotificationSetting?;
                  if (setting == null) {
                    return const Scaffold(
                      body: Center(child: Text('Error: Falta setting')),
                    );
                  }
                  return StudyReminderView(setting: setting);
                },
              ),
              GoRoute(
                path: 'category',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;

                  if (extra == null ||
                      extra['title'] == null ||
                      extra['settings'] == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text('Error: Faltan datos de categoría'),
                      ),
                    );
                  }

                  final title = extra['title'] as String;
                  final settings =
                      extra['settings'] as List<NotificationSetting>;

                  return NotificationCategoryView(
                    title: title,
                    settings: settings,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'support',
            builder: (context, state) => const SupportView(),
          ),
          GoRoute(
            path: 'change-password',
            name: 'change-password',
            builder: (context, state) => const ChangePasswordView(),
          ),
        ],
      ),

      // --- RUTA PARA FEEDBACK DE ÉXITO
      GoRoute(
        path: '/challenge_success',
        name: 'challenge_success',
        builder: (context, state) {
          final int trofeos = (state.extra is int) ? state.extra as int : 0;
          return ChallengeSuccessView(trofeosObtenidos: trofeos);
        },
      ),

      // --- RUTA PARA FEEDBACK DE FRACASO
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

      // 🎉 NUEVA RUTA: Celebración de lenguaje completado
      GoRoute(
        path: '/language-completion',
        name: 'language-completion',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          // Validar que tengamos los datos necesarios
          if (extra == null ||
              extra['completedLanguage'] == null ||
              extra['unlockedLanguages'] == null) {
            // Si no hay data, redirigir al home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/home');
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return LanguageCompletionFlow(
            completedLanguage: extra['completedLanguage'] as String,
            unlockedLanguages: List<String>.from(extra['unlockedLanguages']),
          );
        },
      ),

      // --- Rutas de perfil anidadas
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileView(userId: userId);
        },
        routes: [
          GoRoute(
            path: 'achievements',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return AllAchievementsView(userId: userId);
            },
          ),
          GoRoute(
            path: 'follow/:type',
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
          GoRoute(
            path: 'challenge-history',
            name: 'challenge-history',
            builder: (context, state) => const ChallengeHistoryView(),
          ),
        ],
      ),

      // --- NAVBAR PRINCIPAL
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // HOME
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['home'],
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),

          // RANKING
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['ranking'],
            routes: [
              GoRoute(
                path: '/ranking',
                builder: (context, state) => const RankingView(),
              ),
            ],
          ),

          // DESAFÍO MENSUAL
          StatefulShellBranch(
            navigatorKey: _navigatorKeys['desafiomensual'],
            routes: [
              GoRoute(
                path: '/desafiomensual',
                builder: (context, state) => const DesafioBusquedaView(),
              ),
            ],
          ),

          // PERFIL
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

  // 🔥 GUARDAR la instancia del router para usarla en el listener
  //ref.read(_routerInstanceProvider.notifier).state = router;

  // 🔥 LISTENER DE CONECTIVIDAD (ahora sin ciclo)
  ref.listen<AsyncValue<ConnectivityStatus>>(connectivityProvider, (
    previous,
    next,
  ) {
    next.whenData((status) {
      if (status == ConnectivityStatus.offline) {
        // 🔥 Usamos la variable 'router' local directamente
        Future.microtask(() {
          final currentLocation = router.routerDelegate.currentConfiguration.uri
              .toString();
          if (currentLocation != '/no-internet') {
            router.go('/no-internet');
          }
        });
      }
    });
  });

  // --- 🔥 ¡LA SOLUCIÓN! AÑADIR ESTE LISTENER DE AUTH 🔥 ---
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    next.whenData((authState) {
      // Si el evento es de "PasswordRecovery"
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        // No importa dónde esté el usuario, ¡lo forzamos
        // a la pantalla de actualizar contraseña!
        Future.microtask(() {
          router.go('/update-password');
        });
      }
    });
  });
  // --- FIN DEL BLOQUE AÑADIDO ---

  return router;
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    notifyListeners();

    // Escuchar SÓLO a Auth
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
// [FIN DEL ARCHIVO router.dart]