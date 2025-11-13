// [COMIENZO DEL ARCHIVO desafio_view.dart]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/core/providers/app_provider.dart';

class DesafiosView extends ConsumerWidget {
  const DesafiosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);

    return Scaffold(
      body: desafiosAsync.when(
        data: (data) {
          // --- Sección del Reto Agrupador (Mensual) ---
          if (data.agrupador != null) {
            return ListView(
              children: [
                ExpandableSpecialEventCard(
                  evento: data.agrupador!, // El Reto Agrupador
                  desafiosMensuales:
                      data.individuales, // Los retos individuales del mes
                  completedRetoIds:
                      data.completedRetoIds, // IDs completados para el progreso
                  isParentCompleted: data.isParentCompleted,
                ),
              ],
            );
          }

          // Mensaje si no hay un reto mensual activo
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                '🎉 No hay un evento especial mensual activo en este momento. ¡Vuelve pronto!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// -----------------------------------------------------------------------------------
// --- Widget Expandible para Eventos Especiales (Reto Agrupador) ---
// -----------------------------------------------------------------------------------

class ExpandableSpecialEventCard extends StatefulWidget {
  final DesafioEspecial evento;
  final List<RetoIndividual> desafiosMensuales; // Contenido para la expansión
  final Set<int> completedRetoIds; // IDs de retos completados por el usuario
  final bool isParentCompleted;

  const ExpandableSpecialEventCard({
    super.key,
    required this.evento,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    required this.isParentCompleted,
  });

  @override
  State<ExpandableSpecialEventCard> createState() =>
      _ExpandableSpecialEventCardState();
}

class _ExpandableSpecialEventCardState
    extends State<ExpandableSpecialEventCard> {
  bool _isExpanded = false;

  // Lógica para formatear días restantes
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

  // Lógica para obtener el mes
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

  // ---------------------------------------------------------------------
  // --- Widget Helper para los Hitos (Candados) ---
  // --- (No ha cambiado) ---
  // ---------------------------------------------------------------------
  Widget _buildMilestone({required bool isLocked}) {
    const double size = 20.0; // Tamaño consistente para todos

    // Color de fondo: Verde si está desbloqueado, gris oscuro si está bloqueado
    final Color bgColor = isLocked
        ? Colors.black.withOpacity(0.2)
        : Colors.green.shade300;
    // Color del ícono: Blanco si está desbloqueado, gris claro si está bloqueado
    final Color iconColor = isLocked ? Colors.white54 : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        // Borde sutil para que coincida con la imagen
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
      ),
      child: Icon(
        isLocked ? Icons.lock : Icons.check, // Cambia el ícono
        color: iconColor,
        size: size * 0.6, // Icono más pequeño que el círculo
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    // Lógica para calcular el progreso del evento
    final totalChallenges = widget.desafiosMensuales.length;
    final completedChallenges = widget.completedRetoIds.length;
    final double progress = totalChallenges == 0
        ? 0.0
        : completedChallenges / totalChallenges;

    // Texto de progreso
    final progressTitle = totalChallenges > 0
        ? 'Completa ${totalChallenges} desafíos'
        : 'Sin desafíos definidos';

    // --- Constantes para la barra ---
    const double barHeight = 14.0;
    const double iconSize = 20.0;
    final double borderWidth = 1.0;
    // --- Fin de Constantes ---

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: primaryColor,
      clipBehavior: Clip.antiAlias, // Para que el InkWell respete los bordes
      child: Column(
        children: [
          // -----------------------------------------------------------------
          // CABECERA (Siempre visible y control de expansión)
          // -----------------------------------------------------------------
          InkWell(
            onTap:
                widget
                    .isParentCompleted // Si el padre está completo
                ? null // Bloquea el tap
                : () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Fila Superior (Info + Avatar) ---
                  Row(
                    // ... (Esta parte no cambia) ...
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
                                _getMes(widget.evento.fechaFin),
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
                              widget.evento.titulo,
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
                                  widget.isParentCompleted
                                      ? Icons
                                            .check_circle // Icono de completado
                                      : Icons.timer, // Icono de timer
                                  color: widget.isParentCompleted
                                      ? Colors.white
                                      : Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isParentCompleted
                                      ? "¡EVENTO COMPLETADO!" // Texto de completado
                                      : _formatTiempoRestante(
                                          widget.evento.fechaFin,
                                        ), // Texto de tiempo
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
                      const SizedBox(width: 16),
                      // Avatar/Imagen (Placeholder)
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.star, color: primaryColor, size: 30),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------
                  // --- ¡SECCIÓN DE PROGRESO CON BARRA SEGMENTADA! ---
                  // -----------------------------------------------------

                  // 1. Fila de Textos (Título y Conteo)
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
                  const SizedBox(height: 12), // Espacio antes de la barra
                  // 2. Barra de Progreso Personalizada (con Stack y Borde)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;

                      return Container(
                        // Altura total para la barra, el borde y el hito que sobresale
                        height:
                            iconSize +
                            (borderWidth * 2), // El hito define la altura
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Fondo transparente
                          borderRadius: BorderRadius.circular(
                            barHeight / 2 + 5,
                          ),
                          border: Border.all(
                            color: Colors.black.withOpacity(
                              0.3,
                            ), // Color del borde
                            width: borderWidth,
                          ),
                        ),
                        child: Stack(
                          // Alinear todo al centro-izquierda
                          alignment: Alignment.centerLeft,
                          children: [
                            // --- Capa 1: Fondo de la Barra ---
                            // Centrado verticalmente y con padding horizontal
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: borderWidth,
                                vertical:
                                    (iconSize - barHeight) / 2 + borderWidth,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  barHeight / 2,
                                ),
                                child: Container(
                                  height: barHeight,
                                  width: totalWidth - (borderWidth * 2),
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),

                            // --- Capa 2: Progreso de la Barra (verde) ---
                            // Centrado y animado
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: borderWidth,
                                vertical:
                                    (iconSize - barHeight) / 2 + borderWidth,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  barHeight / 2,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                  height: barHeight,
                                  width:
                                      (totalWidth - (borderWidth * 2)) *
                                      progress,
                                  color: Colors.green.shade300,
                                ),
                              ),
                            ),

                            // --- Capa 3: Los Hitos (Bolitas) ---
                            // Posicionados dinámicamente
                            if (totalChallenges > 0)
                              ...List.generate(totalChallenges, (index) {
                                final desafio = widget.desafiosMensuales[index];
                                final isCompleted = widget.completedRetoIds
                                    .contains(desafio.idReto);
                                final isLocked = !isCompleted;

                                // Calcula la posición horizontal para cada hito
                                // Lo centra en medio de su segmento fraccional
                                final segmentWidth =
                                    (totalWidth - (borderWidth * 2)) /
                                    totalChallenges;
                                final hitoPosition =
                                    (segmentWidth * index) +
                                    (segmentWidth / 2) -
                                    (iconSize / 2);

                                return Positioned(
                                  left: hitoPosition.clamp(
                                    0.0,
                                    totalWidth - iconSize - (borderWidth * 2),
                                  ),
                                  // Centrar verticalmente el hito
                                  top: borderWidth,
                                  child: _buildMilestone(isLocked: isLocked),
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                  // --- FIN DE LA SECCIÓN DE PROGRESO ---
                  // Icono para la expansión
                  const SizedBox(height: 8),
                  if (!widget
                      .isParentCompleted) // Solo muestra si no está completo
                    Center(
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------------------------
          // CONTENIDO EXPANDIBLE (con AnimatedSwitcher)
          // -----------------------------------------------------------------------------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), // Duración deseada
            // Define cómo se anima la transición
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                // Usa la animación para controlar el 'sizeFactor'
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn, // La curva suave
                ),
                axis: Axis.vertical, // Anima verticalmente
                child: child,
              );
            },
            // El 'child' del AnimatedSwitcher cambia según _isExpanded
            child: _isExpanded
                // 1. SI ESTÁ EXPANDIDO: Muestra el contenido
                // Usamos una Key para que AnimatedSwitcher sepa que este
                // es un widget diferente al Container vacío.
                ? Padding(
                    key: const ValueKey('expanded_content'),
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la lista de desafíos
                        const Text(
                          'RETOS INDIVIDUALES DEL EVENTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Lista de Retos Mensuales
                        if (widget.desafiosMensuales.isEmpty)
                          const Text(
                            'No hay retos definidos para este evento.',
                            style: TextStyle(color: Colors.white70),
                          )
                        else
                          ...widget.desafiosMensuales.map(
                            (desafio) => MonthlyChallengeItem(
                              desafio: desafio,
                              parentColor: primaryColor,
                              isCompleted: widget.completedRetoIds.contains(
                                desafio.idReto,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                // 2. SI ESTÁ COLAPSADO: Muestra un contenedor vacío.
                // (En lugar de SizedBox, usamos Container() que es un tipo
                // diferente de widget, y AnimatedSwitcher lo detecta mejor).
                : Container(key: const ValueKey('collapsed_content')),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------------
// --- Item para cada Desafío Mensual (dentro del expandible, con estado de completado) ---
// -----------------------------------------------------------------------------------
class MonthlyChallengeItem extends ConsumerWidget {
  final RetoIndividual desafio;
  final Color parentColor;
  final bool isCompleted;

  const MonthlyChallengeItem({
    super.key,
    required this.desafio,
    required this.parentColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Color.lerp(parentColor, Colors.black, 0.3),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.code,
          color: isCompleted ? Colors.green.shade300 : Colors.white,
        ),
        title: Text(
          desafio.titulo,
          style: TextStyle(
            color: isCompleted ? Colors.white70 : Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white70,
          ),
        ),
        subtitle: Text('', style: const TextStyle(color: Colors.white70)),
        trailing: isCompleted
            ? const Icon(Icons.check, color: Colors.greenAccent)
            : const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
        onTap: isCompleted
            ? null
            : () {
                ref.read(navigationReturnPathProvider.notifier).state =
                    '/desafiomensual';
                context.push('/reto/${desafio.idReto}/${desafio.nivelId}');
              },
      ),
    );
  }
}
// [FIN DEL ARCHIVO desafio_view.dart]