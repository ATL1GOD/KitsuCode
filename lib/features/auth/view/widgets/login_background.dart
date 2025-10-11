import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kitsucode/features/auth/view/widgets/login_form.dart';

class LoginBackground extends StatelessWidget {
  final bool isMobile;
  final Widget child;

  const LoginBackground({
    super.key,
    required this.isMobile,
    this.child = const LoginForm(),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // El widget Stack te permite apilar widgets uno encima del otro.
    return Stack(
      fit: StackFit.expand, // Asegura que el Stack ocupe toda la pantalla
      children: [
        // 1. FONDO CON GRADIENTE
        // Una base de color degradado es más atractiva que un color sólido.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withAlpha(51),
                colorScheme.tertiary.withAlpha(51),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Burbuja de Python
        Positioned(
          top: screenHeight * -0.1,
          left: screenWidth * -0.02,
          child: Transform.rotate(
            angle: -math.pi / 4, // Rotación de -45 grados
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/burbuja_python.png',
                width: screenWidth * 0.5,
              ),
            ),
          ),
        ),

        // Burbuja de Java
        Positioned(
          top: screenHeight * -0.15,
          right: screenWidth * -0.1,
          child: Transform.rotate(
            angle: math.pi / 6, // Rotación de 30 grados
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/burbuja_java.png',
                width: screenWidth * 0.5,
              ),
            ),
          ),
        ),

        // Burbuja de C
        Positioned(
          top: screenHeight * -0.05,
          left: screenWidth * 0.3,
          child: Transform.rotate(
            angle: math.pi / 10,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/burbuja_c.png',
                width: screenWidth * 0.5,
              ),
            ),
          ),
        ),

        // 3. CONTENIDO PRINCIPAL (Formulario de Login)
        // Usamos Center y otros widgets para asegurar que el formulario
        // esté bien presentado y sea funcional en diferentes tamaños de pantalla.
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/fox_login.png',
                      height: isMobile ? 320 : 400,
                    ),
                    const SizedBox(height: 32),
                    child, // --- USE THE CHILD WIDGET ---
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
