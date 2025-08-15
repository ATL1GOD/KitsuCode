import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para que el header sea responsivo
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Wavy header en la parte superior
          ClipPath(
            clipper: WavyClipper(),
            child: Container(
              height: size.height * 0.4, // Aproximadamente 40% de la pantalla
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0F2F1), // Un verde azulado muy claro
                    Color(0xFFB2DFDB), // Un poco más oscuro
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Hoja decorativa en la esquina superior izquierda (simulada)
          Positioned(
            top: 40, // Ajustado para que se vea bien sobre la ola
            left: 10,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.eco,
                size: 120,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),

          // Hojas en la parte inferior (simuladas)
          Positioned(
            bottom: -80,
            left: 0,
            right: 0,
            child: Icon(
              Icons.eco,
              size: 400,
              color: const Color(
                0xFF00796B,
              ).withOpacity(0.1), // Opacidad reducida
            ),
          ),

          // El contenido principal de la pantalla
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Clipper personalizado para crear la curva ondulada.
class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    var firstControlPoint = Offset(size.width / 4, size.height * 0.7);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.8);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * (3 / 4), size.height * 0.9);
    var secondEndPoint = Offset(size.width, size.height * 0.8);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
