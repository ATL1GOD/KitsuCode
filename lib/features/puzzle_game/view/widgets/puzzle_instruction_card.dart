import 'package:flutter/material.dart';

class PuzzleInstructionCard extends StatelessWidget {
  final String text;

  const PuzzleInstructionCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(16),
        // --- ¡"BRILLO" / "GLOW" TEMÁTICO AÑADIDO! ---
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(60), // Sombra suave del color del lenguaje
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        // --- FIN DE LA MODIFICACIÓN ---
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
