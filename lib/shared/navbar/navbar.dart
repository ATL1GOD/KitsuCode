import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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
        // Transform.scale(
        //   scale: 1.5,
        //   child:
        Image.asset(
          'assets/images/home/icon_home.webp',
          width: 60,
          height: 60,
          // ),
        ),
        Image.asset('assets/images/home/icon_rank4.png', width: 60, height: 60),

        // Transform.scale(
        //   scale: 1.5,
        // child:
        Image.asset(
          'assets/images/home/icon_amigos.webp',
          width: 55,
          height: 55,
        ),
        // ),
        // Transform.scale(
        //   scale: 1.5,
        //   child:
        Image.asset(
          'assets/images/home/icon_perfil.webp',
          width: 60,
          height: 60,
        ),
        // ),
      ],
      color: colorScheme.secondary,

      buttonBackgroundColor: Colors.transparent,

      backgroundColor: colorScheme.secondaryContainer,

      animationCurve: Curves.easeOutCubic, //
      animationDuration: const Duration(milliseconds: 900),
      onTap: onTap,
      letIndexChange: (index) => true,
    );
  }
}
