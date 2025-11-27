// features/desafio/presentation/widgets/segmented_event_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class SegmentedEventProgressBar extends StatelessWidget {
  final int totalChallenges;
  final double progress;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
  final Color primaryColor;

  const SegmentedEventProgressBar({
    super.key,
    required this.totalChallenges,
    required this.progress,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    this.primaryColor = Colors.blue,
  });

  Widget _buildMilestone({required bool isLocked}) {
    const double size = 28.0;

    if (!isLocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: primaryColor,
            size: size * 0.6,
            weight: 800,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          color: Colors.white.withOpacity(0.7),
          size: size * 0.55,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 8.0;
    const double iconSize = 28.0;
    // Definimos el padding como constante para usarlo en el cálculo
    const double horizontalPadding = 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // Calculamos el ancho real disponible restando el padding de ambos lados
        final availableWidth = totalWidth - (horizontalPadding * 2);

        if (totalChallenges == 0) return const SizedBox();

        return SizedBox(
          height: iconSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // --- Capa 1: Fondo de la Barra (Track) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Center(
                  child: Container(
                    height: barHeight,
                    width: availableWidth, // Usamos el ancho corregido
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                ),
              ),

              // --- Capa 2: Progreso de la Barra (Relleno) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Align(
                  // 🔥 CAMBIO: Usamos Align en lugar de Center+Row
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: barHeight,
                    // 🔥 CORRECCIÓN: Calculamos el ancho basado en el espacio disponible (sin padding)
                    width: availableWidth * progress,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Capa 3: Los Hitos (Bolitas) ---
              ...List.generate(totalChallenges, (index) {
                final desafio = desafiosMensuales[index];
                final isCompleted = completedRetoIds.contains(desafio.idReto);
                final isLocked = !isCompleted;

                // Ajustamos el cálculo de posición para que coincida con el área "dibujable"
                final segmentWidth = totalWidth / totalChallenges;
                final hitoPosition =
                    (segmentWidth * index) +
                    (segmentWidth / 2) -
                    (iconSize / 2);

                return Positioned(
                  left: hitoPosition.clamp(0.0, totalWidth - iconSize),
                  top: 0,
                  bottom: 0,
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
