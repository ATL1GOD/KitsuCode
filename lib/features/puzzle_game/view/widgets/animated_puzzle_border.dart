import 'package:flutter/material.dart';

class AnimatedPuzzleBorder extends StatefulWidget {
  final Widget child;
  const AnimatedPuzzleBorder({super.key, required this.child});

  @override
  State<AnimatedPuzzleBorder> createState() => _AnimatedPuzzleBorderState();
}

class _AnimatedPuzzleBorderState extends State<AnimatedPuzzleBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Velocidad de la rotación
    )..repeat(); // Bucle infinito
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RotationTransition(
      turns: _controller,
      child: Container(
        padding: const EdgeInsets.all(3.0), // Ancho del borde
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18), // Radio del borde
          // Usamos un SweepGradient para el efecto de borde animado
          gradient: SweepGradient(
            center: Alignment.center,
            colors: [
              colorScheme.primary, // Color del lenguaje
              colorScheme.secondary, // Color del lenguaje
              colorScheme.primary.withAlpha(50), // Transparente en medio para efecto difuminado
              colorScheme.primary, // Vuelve al inicio
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: widget.child, // El contenido dentro del borde de la tarjeta de instrucción
      ),
    );
  }
}