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
          scale: 2.9, // <-- Aumenta la imagen visualmente (30 * 1.7 = 51px)
          child: Image.asset(
            'images/navbar/home_navbar.png',
            width: 30, // <-- Mantiene el espacio del layout pequeño
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5, // <-- Aumenta la imagen visualmente (30 * 1.7 = 51px)
          child: Image.asset(
            'images/navbar/social_navbar.png',
            width: 30, // <-- Mantiene el espacio del layout pequeño
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5, // <-- Aumenta la imagen visualmente (30 * 1.7 = 51px)
          child: Image.asset(
            'images/navbar/social_navbar.png',
            width: 30, // <-- Mantiene el espacio del layout pequeño
            height: 30,
          ),
        ),
        Transform.scale(
          scale: 1.5, // <-- Aumenta la imagen visualmente (30 * 1.7 = 51px)
          child: Image.asset(
            'images/navbar/social_navbar.png',
            width: 30, // <-- Mantiene el espacio del layout pequeño
            height: 30,
          ),
        ),
      ],
      // El color de fondo de la barra será el color primario del tema.
      color: colorScheme.secondary,
      // El color del botón seleccionado será el color secundario del tema.
      buttonBackgroundColor: Colors.transparent,
      // El fondo general detrás de la barra es transparente para mostrar el contenido de la pantalla.
      backgroundColor: Colors.transparent,
      animationCurve: Curves.easeOutCubic,
      animationDuration: const Duration(milliseconds: 600),
      onTap: onTap,
      letIndexChange: (index) => true,
    );
  }
}
