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
      appBar: AppBar(title: const Text('Desafíos Mensuales')),
      body: desafiosAsync.when(
        data: (data) {
          // --- Sección del Reto Agrupador (Mensual) ---
          if (data.agrupador != null) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
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
  final bool isParentCompleted; // <-- ¡RECIBE EL NUEVO VALOR!

  const ExpandableSpecialEventCard({
    super.key,
    required this.evento,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    required this.isParentCompleted, // <-- ¡AÑADE ESTO AL CONSTRUCTOR!
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
      'DICIEMBRE',
    ];
    return meses[fecha.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    // Lógica para calcular el progreso del evento
    final totalChallenges = widget.desafiosMensuales.length;
    final completedChallenges = widget.completedRetoIds.length;
    final progress = totalChallenges > 0
        ? completedChallenges / totalChallenges
        : 0.0;
    final progressPercentage = (progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: primaryColor,
      child: Column(
        children: [
          // CABECERA (Siempre visible y control de expansión)
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
              child: Row(
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
                        Text(
                          widget.evento.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // --- ¡¡LÓGICA DE TEXTO COMPLETADO!! ---
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
                            const Icon(
                              Icons.timer,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTiempoRestante(widget.evento.fechaFin),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Avatar/Imagen (Placeholder de Junior)
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.star, color: primaryColor, size: 30),
                  ),
                  // Icono para la expansión
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------------------------
          // CONTENIDO EXPANDIBLE
          // -----------------------------------------------------------------------------------
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de progreso y texto
                  const SizedBox(height: 10),
                  Text(
                    'DESAFÍOS COMPLETADOS ($completedChallenges/$totalChallenges - $progressPercentage%)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progreso
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade300,
                    ),
                  ),
                  const SizedBox(height: 15),

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
                        // Verificamos si el reto está en el Set de IDs completados
                        isCompleted: widget.completedRetoIds.contains(
                          desafio.idReto,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
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
  final RetoIndividual desafio; // Usar el nuevo modelo
  final Color parentColor;
  final bool isCompleted; // Indica si el reto fue completado

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
      color: Color.lerp(parentColor, Colors.black, 0.2),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.code, // Ícono de completado
          color: isCompleted ? Colors.green.shade300 : Colors.white,
        ),
        title: Text(
          desafio.titulo,
          style: TextStyle(
            color: Colors.white,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : null, // Tachado si está completo
            decorationColor: Colors.white70,
          ),
        ),
        subtitle: Text('', style: const TextStyle(color: Colors.white70)),
        trailing: isCompleted
            ? const Icon(
                Icons.check,
                color: Colors.greenAccent,
              ) // Muestra un check final si está completo
            : const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: isCompleted
            ? null // Desactiva el tap si ya está completo
            : () {
                // --- ¡¡ESTE ES EL CAMBIO!! ---
                // 1. Establecemos la ruta de retorno
                ref.read(navigationReturnPathProvider.notifier).state =
                    '/desafiomensual';

                // 2. Navegamos al distribuidor de retos (el MISMO de siempre)
                // ¡No necesitas un distribuidor nuevo!
                context.push('/reto/${desafio.idReto}/${desafio.nivelId}');
              },
      ),
    );
  }
}
// [FIN DEL ARCHIVO desafio_view.dart]