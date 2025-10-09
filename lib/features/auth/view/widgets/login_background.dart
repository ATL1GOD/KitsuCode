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
                    Color(0xFFFFDFC4), // Un verde azulado muy claro
                    Color(0xFFEF6C00), // Un poco más oscuro
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            top: 70,
            left: 10,
            child: Transform.rotate(
              angle: -0.3,
              child: Image.asset(
                'assets/images/orejas.png',
                width: 100,
                color: Colors.white.withAlpha(77),
              ),
            ),
          ),

          // Orejas derecha
          Positioned(
            top: 50,
            right: 15,
            child: Transform.rotate(
              angle: 0.4,
              child: Image.asset(
                'assets/images/orejas.png',
                width: 90,
                color: Colors.white.withAlpha(90),
              ),
            ),
          ),

          // 🌿 Hoja izquierda (esquina)
          Positioned(
            top: 20,
            left: 20,
            child: Icon(Icons.eco, size: 60, color: Colors.white.withAlpha(64)),
          ),

          // 🌿 Hoja derecha (esquina)
          Positioned(
            top: 20,
            right: 20,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.eco,
                size: 60,
                color: Colors.white.withAlpha(64),
              ),
            ),
          ),

          // Huellas izquierda
          Positioned(
            top: 200, // más abajo que antes
            left: 20, // pegado a la izquierda
            child: Transform.rotate(
              angle: -1,
              child: Image.asset(
                'assets/images/huellas.png',
                width: 65,
                color: Colors.white.withAlpha(90),
              ),
            ),
          ),

          Positioned(
            top: 150,
            right: 60,
            child: Transform.rotate(
              angle: 0.25,
              child: Image.asset(
                'assets/images/huellas.png',
                width: 55,
                color: Colors.white.withAlpha(77),
              ),
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
    path.lineTo(0, size.height * 0.9);

    // 1ª curva extremo izquierdo
    var firstControlPoint = Offset(size.width * 0.125, size.height * 1);
    var firstEndPoint = Offset(size.width * 0.25, size.height * 0.85);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // 2ª curva mitad izquierda
    var secondControlPoint = Offset(size.width * 0.375, size.height * 0.55);
    var secondEndPoint = Offset(size.width * 0.5, size.height * 0.65);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Curva extra suaviza valle entre 2ª y 3ª
    var extraControlPoint = Offset(size.width * 0.55, size.height * 0.7);
    var extraEndPoint = Offset(size.width * 0.625, size.height * 0.65);
    path.quadraticBezierTo(
      extraControlPoint.dx,
      extraControlPoint.dy,
      extraEndPoint.dx,
      extraEndPoint.dy,
    );

    // 3ª curva mitad-derecho
    var thirdControlPoint = Offset(size.width * 0.6875, size.height * 0.6);
    var thirdEndPoint = Offset(size.width * 0.75, size.height * 0.85);
    path.quadraticBezierTo(
      thirdControlPoint.dx,
      thirdControlPoint.dy,
      thirdEndPoint.dx,
      thirdEndPoint.dy,
    );

    // 4ª curva extremo derecho
    var fourthControlPoint = Offset(size.width * 0.875, size.height * 1.05);
    var fourthEndPoint = Offset(size.width, size.height * 0.85);
    path.quadraticBezierTo(
      fourthControlPoint.dx,
      fourthControlPoint.dy,
      fourthEndPoint.dx,
      fourthEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
