import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícono de idioma
          SvgPicture.asset('assets/italian.svg', width: 26, height: 26),
          // Sección de Racha
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/racha.svg', width: 26, height: 26),
              const SizedBox(width: 8),
              const Text(
                '0',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  fontSize: 16.0,
                  color: Color(0xFF37464F),
                ),
              ),
            ],
          ),
          // Sección de Diamantes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/diamante.svg', width: 26, height: 26),
              const SizedBox(width: 8),
              const Text(
                '1000',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  fontSize: 16.0,
                  color: Color(0xFF49C0F8),
                ),
              ),
            ],
          ),
          // Sección de Vidas
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/vidas.svg', width: 26, height: 26),
              const SizedBox(width: 8.0),
              const Text(
                '5',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  fontSize: 16.0,
                  color: Color(0xFFEE5555),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
