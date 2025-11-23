// features/desafio/presentation/widgets/segmented_event_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart'; // Modelos

class SegmentedEventProgressBar extends StatelessWidget {
  final int totalChallenges;
  final double progress;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;

  const SegmentedEventProgressBar({
    super.key,
    required this.totalChallenges,
    required this.progress,
    required this.desafiosMensuales,
    required this.completedRetoIds,
  });

  // --- Widget Helper para los Hitos (Candados) ---
  // (Ahora es parte de este widget)
  Widget _buildMilestone({required bool isLocked}) {
    const double size = 20.0;
    final Color bgColor = isLocked
        ? Colors.black.withAlpha(51)
        : Colors.green.shade300;
    final Color iconColor = isLocked ? Colors.white54 : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withAlpha(51), width: 1),
      ),
      child: Icon(
        isLocked ? Icons.lock : Icons.check,
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Constantes para la barra ---
    const double barHeight = 14.0;
    const double iconSize = 20.0;
    final double borderWidth = 1.0;
    // --- Fin de Constantes ---

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Container(
          height: iconSize + (borderWidth * 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(barHeight / 2 + 5),
            border: Border.all(
              color: Colors.black.withAlpha(77),
              width: borderWidth,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // --- Capa 1: Fondo de la Barra ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: borderWidth,
                  vertical: (iconSize - barHeight) / 2 + borderWidth,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: Container(
                    height: barHeight,
                    width: totalWidth - (borderWidth * 2),
                    color: Colors.black.withAlpha(77),
                  ),
                ),
              ),
              // --- Capa 2: Progreso de la Barra (verde) ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: borderWidth,
                  vertical: (iconSize - barHeight) / 2 + borderWidth,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: barHeight,
                    width: (totalWidth - (borderWidth * 2)) * progress,
                    color: Colors.green.shade300,
                  ),
                ),
              ),
              // --- Capa 3: Los Hitos (Bolitas) ---
              if (totalChallenges > 0)
                ...List.generate(totalChallenges, (index) {
                  final desafio = desafiosMensuales[index];
                  final isCompleted = completedRetoIds.contains(desafio.idReto);
                  final isLocked = !isCompleted;

                  final segmentWidth =
                      (totalWidth - (borderWidth * 2)) / totalChallenges;
                  final hitoPosition =
                      (segmentWidth * index) +
                      (segmentWidth / 2) -
                      (iconSize / 2);

                  return Positioned(
                    left: hitoPosition.clamp(
                      0.0,
                      totalWidth - iconSize - (borderWidth * 2),
                    ),
                    top: borderWidth,
                    child: _buildMilestone(isLocked: isLocked),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
