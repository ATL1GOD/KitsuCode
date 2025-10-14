// lib/shared/navbar/navbar.dart

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el esquema de colores del tema actual.
    final colorScheme = Theme.of(context).colorScheme;

    return CurvedNavigationBar(
      index: currentIndex,
      height: 65.0,
      items: <Widget>[
        Transform.scale(
          scale: 2.9,
          child: Image.asset(
            'assets/images/navbar/home_navbar.png',
            width: 30,
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/images/navbar/social_navbar.png',
            width: 30,
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/images/navbar/social_navbar.png',
            width: 30,
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/images/navbar/social_navbar.png',
            width: 30,
            height: 30,
          ),
        ),
      ],

      // --- El color de la barra (naranja oscuro). Se mantiene. ---
      color: colorScheme.secondary,

      buttonBackgroundColor: Colors.transparent,

      // --- ¡AQUÍ ESTÁ LA SOLUCIÓN! ---
      // El fondo detrás de la curva ahora es del MISMO color que la barra.
      // Esto crea el efecto de una pieza sólida.
      backgroundColor: colorScheme.secondaryContainer,

      animationCurve: Curves.easeOutCubic,
      animationDuration: const Duration(milliseconds: 600),
      onTap: onTap,
      letIndexChange: (index) => true,
    );
  }
}
