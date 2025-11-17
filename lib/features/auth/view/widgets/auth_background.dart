import 'dart:math';
import 'package:flutter/material.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;
  final bool isScrollable; // <-- AÑADE ESTO
  final bool showFox; // <-- AÑADE ESTO

  const AuthBackground({
    super.key,
    required this.child,
    this.isScrollable = true,
    this.showFox = true,
  });

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  final int _shapeCount = 10;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _shapeCount,
      (index) => AnimationController(
        duration: Duration(seconds: _random.nextInt(10) + 20),
        vsync: this,
      )..repeat(reverse: true),
    );

    _animations = List.generate(_shapeCount, (index) {
      final beginOffset = Offset(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1,
      );
      final endOffset = Offset(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1,
      );
      return Tween<Offset>(begin: beginOffset, end: endOffset).animate(
        CurvedAnimation(parent: _controllers[index], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con gradiente mejorado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(204),
                  const Color(0xFF0E0028), // Un morado oscuro/azulado
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.9],
              ),
            ),
          ),
          // Formas animadas
          ...List.generate(_shapeCount, (index) {
            return SlideTransition(
              position: _animations[index],
              child: Opacity(
                opacity: 0.15,
                child: Container(
                  width: _random.nextDouble() * 150 + 50,
                  height: _random.nextDouble() * 150 + 50,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? colorScheme.secondary
                        : colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
          // Contenido principal centrado
          Center(
            // --- ### INICIO DE LA MODIFICACIÓN ### ---
            child: widget.isScrollable
                // 1. VERSIÓN CON SCROLL (Para Login/Registro)
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isSmallScreen && widget.showFox) ...[
                            // <-- Check
                            Image.asset(
                              'assets/images/auth/fox_login.png',
                              height: 280,
                            ),
                            const SizedBox(height: 24),
                          ],
                          widget.child,
                        ],
                      ),
                    ),
                  )
                // 2. VERSIÓN SIN SCROLL (Para Política de Privacidad)
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: widget.child, // <-- Solo renderiza el hijo
                    ),
                  ),
            // --- ### FIN DE LA MODIFICACIÓN ### ---
          ),
        ],
      ),
    );
  }
}
