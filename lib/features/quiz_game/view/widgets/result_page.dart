// lib/features/quiz_game/view/widgets/result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // --- ¡CAMBIO 1! ---
import 'package:kitsucode/core/utils/app_colors.dart';

// --- ¡CAMBIO 2! (Importaciones para la puntuación) ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
// --- FIN CAMBIO 2 ---

// --- ¡CAMBIO 3! (Convertido a ConsumerStatefulWidget) ---
class QuizResultPage extends ConsumerStatefulWidget {
  final int marks;
  final int totalQuestions;
  final int durationInSeconds;

  // --- ¡CAMBIO 4! (Añadimos el retoId, ahora es String) ---
  final String retoId;

  const QuizResultPage({
    super.key, // <-- Corregido
    required this.marks,
    required this.totalQuestions,
    required this.durationInSeconds,
    required this.retoId, // <-- Requerido
  });

  @override
  // --- ¡CAMBIO 5! ---
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  final List<String> images = [
    "assets/images/success.png",
    "assets/images/good.png",
    "assets/images/bad.png",
  ];

  late String image;
  late int percentage;
  late String formattedTime;

  @override
  void initState() {
    super.initState();

    final double scoreRatio = widget.marks / (widget.totalQuestions * 5);
    if (scoreRatio < 0.5) {
      image = images[2]; // bad
    } else if (scoreRatio < 0.8) {
      image = images[1]; // good
    } else {
      image = images[0]; // success
    }

    percentage = (scoreRatio * 100).round();

    final int minutes = widget.durationInSeconds ~/ 60;
    final int seconds = widget.durationInSeconds % 60;
    formattedTime =
        "${minutes.toString()}:${seconds.toString().padLeft(2, '0')}";

    // --- ¡CAMBIO 6! (Llamar al envío del intento) ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitAttempt();
    });
  }

  // --- ¡CAMBIO 7! (Función de envío CORREGIDA) ---
  Future<void> _submitAttempt() async {
    // Asumimos que si saca más del 50% es "completado"
    final bool esCorrecto = (percentage > 50);

    // Obtenemos el ID del reto como int
    final int retoIdAsInt;
    try {
      retoIdAsInt = int.parse(widget.retoId);
    } catch (e) {
      debugPrint("Error: retoId no es un número válido: ${widget.retoId}");
      return;
    }

    try {
      final repository = ref.read(challengeRepositoryProvider);
      await repository.submitChallengeAttempt(
        retoId: retoIdAsInt, // <-- CORREGIDO
        fueExitoso: esCorrecto, // <-- CORREGIDO
        tiempoQueTardo: widget.durationInSeconds, // <-- CORREGIDO
      );

      // Refrescar la UI (AppBar y Ranking)
      ref.read(appBarProvider.notifier).fetchStats();
      ref.invalidate(globalRankingProvider);
    } catch (e) {
      debugPrint("Error al enviar intento de quiz: $e");
    }
  }
  // --- FIN CAMBIO 7 ---

  @override
  Widget build(BuildContext context) {
    // ... (El resto de tu código: build, _StatCard...
    // ... no necesitan cambios) ...
    final brightness = MediaQuery.of(context).platformBrightness;
    final colorScheme = (brightness == Brightness.dark)
        ? pythonDarkColorScheme
        : pythonLightColorScheme;

    return Theme(
      data: ThemeData.from(colorScheme: colorScheme, useMaterial3: true),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Image.asset(image, height: 200, fit: BoxFit.contain),
                const SizedBox(height: 24),
                Text(
                  '¡Completaste la práctica!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      label: 'EXP TOTALES',
                      value: widget.marks.toString(),
                      icon: Icons.star_rounded,
                      colorScheme: colorScheme,
                    ),
                    _StatCard(
                      label: 'BIEN',
                      value: '$percentage%',
                      icon: Icons.check_circle_rounded,
                      colorScheme: colorScheme,
                    ),
                    _StatCard(
                      label: 'ÁGIL',
                      value: formattedTime,
                      icon: Icons.timer_rounded,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: colorScheme.outline, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
