import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';
import 'segmented_event_progress_bar.dart';

class SpecialEventCardHeader extends StatelessWidget {
  final DesafioEspecial evento;
  final bool isParentCompleted;
  final String progressTitle;
  final int completedChallenges;
  final int totalChallenges;
  final double progress;
  final bool isExpanded;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
  final Color primaryColor;

  const SpecialEventCardHeader({
    super.key,
    required this.evento,
    required this.isParentCompleted,
    required this.progressTitle,
    required this.completedChallenges,
    required this.totalChallenges,
    required this.progress,
    required this.isExpanded,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    required this.primaryColor,
  });

  String _formatTiempoRestante(DateTime fechaFin) {
    final now = DateTime.now();
    final difference = fechaFin.difference(now);
    if (difference.isNegative) return 'FINALIZADO';
    final days = difference.inDays;
    if (days == 0) {
      final hours = difference.inHours;
      return '$hours HORAS';
    }
    return '$days DÍAS';
  }

  String _getMes(DateTime fecha) {
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return meses[fecha.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isParentCompleted
                                ? [
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            isParentCompleted
                                ? "¡COMPLETADO!"
                                : _getMes(evento.fechaFin),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          evento.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 120),
                ],
              ),
              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isParentCompleted
                            ? Icons.emoji_events_rounded
                            : Icons.timer,
                        color: Colors.white,
                        size: isParentCompleted ? 20 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isParentCompleted
                            ? "¡Has completado el evento!"
                            : _formatTiempoRestante(evento.fechaFin),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$completedChallenges / $totalChallenges',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SegmentedEventProgressBar(
                totalChallenges: totalChallenges,
                progress: progress,
                desafiosMensuales: desafiosMensuales,
                completedRetoIds: completedRetoIds,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 8),

              Center(
                child: AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 10,
          right: 30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.26),
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),

                if (isParentCompleted)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: OptimizedImage(
              imagePath: evento.webpEspecial,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              enableCache: true,
              isLocalAsset: false,
            ),
          ),
        ),
      ],
    );
  }
}
