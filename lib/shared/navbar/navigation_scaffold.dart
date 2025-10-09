// En: lib/shared/widgets/navbar/navigation_scaffold.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/shared/navbar/navbar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CAMBIO 1: PERMITIR QUE EL CUERPO SE DIBUJE DETRÁS DE LA NAVBAR ---
      // Esta propiedad es la más importante. Le dice al Scaffold que el 'body'
      // (tus pantallas como ProfileView) debe ocupar todo el espacio vertical,
      // dibujándose por debajo de la barra de navegación.
      extendBody: true,

      // --- CAMBIO 2: HACER EL FONDO DEL SCAFFOLD TRANSPARENTE ---
      // Esto asegura que si una pantalla no tiene un fondo definido, no se
      // muestre un color blanco por defecto, permitiendo que el degradado de
      // tu ProfileView sea el único fondo visible.
      backgroundColor: Colors.transparent,

      // El cuerpo es el 'navigationShell', que se encarga de mostrar la vista correcta.
      body: navigationShell,

      // --- CAMBIO 3: ENVOLVER LA NAVBAR EN UN THEME PARA QUITAR SU FONDO Y SOMBRA ---
      // Tu widget 'NavBar' probablemente usa un BottomNavigationBar de Flutter
      // por dentro. Al envolverlo en un Theme personalizado, podemos forzar
      // a que su fondo (canvasColor) y su sombra (shadowColor) sean transparentes.
      // Esto elimina tanto la "zona blanca" como la "línea divisora".
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: NavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(index),
        ),
      ),
    );
  }

  // Método que se ejecuta al presionar un ícono de la NavBar.
  void _onTap(int index) {
    // Usamos 'goBranch' para cambiar de pestaña sin perder el estado de las otras.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}