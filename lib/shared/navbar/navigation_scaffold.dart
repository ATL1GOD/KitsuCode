import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/shared/navbar/navbar.dart';

// Provider que guarda el índice actual de la barra de navegación
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Scaffold principal que incluye la barra de navegación inferior.
/// Usa Riverpod para manejar el índice de navegación y GoRouter para cambiar de pestaña.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // --- Permitir que el body se dibuje detrás de la NavBar ---
      extendBody: true,

      // --- Fondo transparente para evitar "pantallas blancas" ---
      backgroundColor: Colors.transparent,

      // --- El cuerpo: se muestra según la pestaña seleccionada ---
      body: navigationShell,

      // --- Barra de navegación personalizada ---
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: NavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(index, ref),
        ),
      ),
    );
  }

  /// Cambia de pestaña usando goBranch, sin perder el estado de las otras.
  void _onTap(int index, WidgetRef ref) {
    ref.read(navIndexProvider.notifier).state = index;

    navigationShell.goBranch(
      index,
      // Si el usuario toca el mismo ícono, lo lleva al inicio de esa rama.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
