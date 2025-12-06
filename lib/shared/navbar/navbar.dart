import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes_local.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CurvedNavigationBar(
      index: currentIndex,
      height: 65.0,
      items: <Widget>[
        OptimizedLocalImage(
          assetPath: 'assets/images/home/icon_home.webp',
          width: 60,
          height: 60,
        ),
        OptimizedLocalImage(
          assetPath: 'assets/images/home/icon_rank.webp',
          width: 50,
          height: 50,
        ),

        OptimizedLocalImage(
          assetPath: 'assets/images/home/icon_amigos.webp',
          width: 55,
          height: 55,
        ),

        OptimizedLocalImage(
          assetPath: 'assets/images/home/icon_perfil.webp',
          width: 60,
          height: 60,
        ),
      ],
      color: colorScheme.secondary,

      buttonBackgroundColor: Colors.transparent,

      backgroundColor: colorScheme.secondaryContainer,

      animationCurve: Curves.easeOutCubic,
      animationDuration: const Duration(milliseconds: 400),
      onTap: onTap,
      letIndexChange: (index) => true,
    );
  }
}
