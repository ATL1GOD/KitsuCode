import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

// Views
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/navbar/navigation_scaffold.dart'; // Asegúrate de tener este archivo
// import 'package:kitsucode/features/home/view/home_view.dart';
// import 'package:kitsucode/features/home/view/widgets/map_home.dart';

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

// class HomeView extends StatelessWidget {
//   const HomeView({super.key});

//   // Función auxiliar para oscurecer un color
//   Color _darkenColor(Color color, double factor) {
//     return HSLColor.fromColor(color)
//         .withLightness(
//           (HSLColor.fromColor(color).lightness - factor).clamp(0.0, 1.0),
//         )
//         .toColor();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Datos de ejemplo para las secciones del camino
//     final data = <SectionData>[
//       SectionData(
//         color: const Color(0xFF58CC02), // Verde Duolingo
//         colorOscuro: _darkenColor(const Color(0xFF58CC02), 0.1),
//         etapa: 1,
//         seccion: 1,
//         titulo: 'Fundamentos de Nieve',
//       ),
//       SectionData(
//         color: const Color(0xFF1CB0F6), // Azul Duolingo
//         colorOscuro: _darkenColor(const Color(0xFF1CB0F6), 0.1),
//         etapa: 1,
//         seccion: 2,
//         titulo: "Aventura Congelada",
//       ),
//       SectionData(
//         color: const Color(0xFFFF9600), // Naranja Duolingo
//         colorOscuro: _darkenColor(const Color(0xFFFF9600), 0.1),
//         etapa: 1,
//         seccion: 3,
//         titulo: "Reto del Vértice",
//       ),
//     ];

//     return Scaffold(
//       // Hacemos el Scaffold transparente para ver el fondo del Stack
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         title: const Text('Camino Infinito'),
//         // El AppBar también transparente
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       // Usamos un Stack para poner la imagen de fondo
//       body: Stack(
//         children: [
//           // Capa 1: El Fondo de Imagen Repetitivo
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 // Usa el nombre de tu archivo de imagen
//                 image: AssetImage('images/home/mapa_c.png'),
//                 fit: BoxFit.cover, // Cubre el ancho, se repetirá verticalmente
//                 repeat: ImageRepeat
//                     .repeatY, // ¡Esta es la clave para el efecto infinito!
//               ),
//             ),
//           ),
//           // Capa 2: El Camino de Botones (ListView)
//           ListView.separated(
//             padding: const EdgeInsets.all(16.0),
//             itemCount: data.length,
//             itemBuilder: (_, index) => Section(data: data[index]),
//             separatorBuilder: (_, __) => const SizedBox(height: 24.0),
//           ),
//         ],
//       ),
//     );
//   }
// }

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

          // Lista de rutas que el usuario puede visitar SIN estar autenticado
          // --- UPDATED LIST ---
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
