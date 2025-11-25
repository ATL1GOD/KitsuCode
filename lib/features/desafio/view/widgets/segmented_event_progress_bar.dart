// features/desafio/presentation/widgets/segmented_event_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class SegmentedEventProgressBar extends StatelessWidget {
  final int totalChallenges;
  final double progress;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
  final Color primaryColor; // <--- Nuevo parámetro para coordinar colores

  const SegmentedEventProgressBar({
    super.key,
    required this.totalChallenges,
    required this.progress,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    this.primaryColor = Colors.blue, // Valor por defecto por seguridad
  });

  // --- Widget Helper para los Hitos (Candados) Mejorado ---
  Widget _buildMilestone({required bool isLocked}) {
    const double size = 28.0; // Un poco más grandes para que destaquen

    // Diseño Desbloqueado (Completado)
    if (!isLocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white, // Fondo blanco puro
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
            color: primaryColor, // El check toma el color del evento
            size: size * 0.6,
            weight: 800, // Icono más "gordito"
          ),
        ),
      );
    }

    // Diseño Bloqueado
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // Fondo semitransparente oscuro
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
    // --- Constantes para la barra ---
    const double barHeight = 8.0; // Barra más fina para elegancia
    const double iconSize =
        28.0; // Debe coincidir con el size de _buildMilestone
    // Calculamos el padding vertical necesario para centrar la barra respecto a los iconos
    const double verticalPadding = (iconSize - barHeight) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Evitar división por cero si no hay retos
        if (totalChallenges == 0) return const SizedBox();

        return SizedBox(
          height:
              iconSize, // La altura total es la del elemento más alto (el icono)
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // --- Capa 1: Fondo de la Barra (Track) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Center(
                  child: Container(
                    height: barHeight,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(
                        0.2,
                      ), // Track oscuro sutil
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                ),
              ),

              // --- Capa 2: Progreso de la Barra (Relleno) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Center(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: barHeight,
                        width: totalWidth * progress, // Ancho dinámico
                        decoration: BoxDecoration(
                          color: Colors.white, // Barra blanca brillante
                          borderRadius: BorderRadius.circular(barHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Capa 3: Los Hitos (Bolitas) ---
              ...List.generate(totalChallenges, (index) {
                final desafio = desafiosMensuales[index];
                final isCompleted = completedRetoIds.contains(desafio.idReto);
                final isLocked = !isCompleted;

                // Lógica de posición: Centrado en su segmento
                final segmentWidth = totalWidth / totalChallenges;
                final hitoPosition =
                    (segmentWidth * index) +
                    (segmentWidth / 2) -
                    (iconSize / 2);

                return Positioned(
                  left: hitoPosition.clamp(0.0, totalWidth - iconSize),
                  // No necesitamos top, ya que el Stack centra o usamos Center,
                  // pero como usamos Positioned, alineamos verticalmente:
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
