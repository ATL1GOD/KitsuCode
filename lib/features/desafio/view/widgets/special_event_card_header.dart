// features/desafio/presentation/widgets/special_event_card_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // <-- 1. IMPORTA EL PAQUETE
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
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

  // ... (tus funciones _formatTiempoRestante y _getMes se quedan igual) ...
  String _formatTiempoRestante(DateTime fechaFin) {
    final now = DateTime.now();
    final difference = fechaFin.difference(now);
    if (difference.isNegative) {
      return 'FINALIZADO';
    }
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
      'DECEMBRE',
    ];
    return meses[fecha.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // 2. ENVUELVE TODO EN UN STACK
    return Stack(
      // 3. PERMITE QUE LOS HIJOS SE "SALGAN" DEL STACK
      clipBehavior: Clip.none,
      children: [
        // --- CONTENIDO PRINCIPAL DE LA TARJETA ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Fila Superior (Info + Espacio para la estampa) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAG (Mes)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getMes(evento.fechaFin),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // TÍTULO
                        Text(
                          evento.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // TIEMPO RESTANTE
                        Row(
                          children: [
                            Icon(
                              isParentCompleted
                                  ? Icons.check_circle
                                  : Icons.timer,
                              color: isParentCompleted
                                  ? Colors.white
                                  : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isParentCompleted
                                  ? "¡EVENTO COMPLETADO!"
                                  : _formatTiempoRestante(evento.fechaFin),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. DEJA UN ESPACIO PARA LA ESTAMPA
                  //    Esto evita que el texto se ponga debajo de ella.
                  //    Ajusta el 'width' al tamaño de tu estampa.
                  const SizedBox(width: 60),
                ],
              ),
              const SizedBox(height: 16),

              // -----------------------------------------------------
              // --- SECCIÓN DE PROGRESO (Sin cambios) ---
              // -----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progressTitle, // "Completa X desafíos"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completedChallenges / $totalChallenges', // "1 / X"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Barra de Progreso Personalizada (Widget separado) ---
              SegmentedEventProgressBar(
                totalChallenges: totalChallenges,
                progress: progress,
                desafiosMensuales: desafiosMensuales,
                completedRetoIds: completedRetoIds,
              ),

              // Icono para la expansión
              const SizedBox(height: 8),
              if (!isParentCompleted)
                Center(
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 30,
                  ),
                ),
            ],
          ),
        ),

        // 5. AQUÍ VA LA ESTAMPA SVG SUPERPUESTA
        Positioned(
          top: 20, // <-- Ajusta para que "flote" hacia arriba
          right: 40, // <-- Ajusta la posición horizontal
          child: Container(
            width: 150, // Tamaño de la estampa
            height: 130, // Tamaño de la estampa
            decoration: BoxDecoration(
              // Opcional: Añade una sombra para el efecto "resaltado"
              shape: BoxShape.circle, // Asumiendo que tu estampa es redonda
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 5), // Sombra hacia abajo y derecha
                ),
              ],
            ),
            child: SvgPicture.asset(
              '/images/mensual/navidad1.svg', // <-- ¡CAMBIA ESTO POR TU RUTA!
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
