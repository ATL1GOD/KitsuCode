// [COMIENZO DEL ARCHIVO desafio_view.dart]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class DesafiosView extends ConsumerWidget {
  const DesafiosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos')),
      body: desafiosAsync.when(
        data: (desafios) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Sección de Eventos Especiales EXPANDIBLES ---
              if (desafios.especiales.isNotEmpty)
                ...desafios.especiales.map(
                  (evento) =>
                      // Usamos la primera tarjeta de evento especial para agrupar los diarios
                      ExpandableSpecialEventCard(
                        evento: evento,
                        // Pasamos los desafíos diarios como contenido expandible.
                        // Adapta esta lista si tu provider ahora trae desafíos específicos relacionados.
                        desafiosMensuales: desafios.diarios,
                      ),
                ),

              const SizedBox(height: 30),

              // --- Sección de Desafíos Diarios "Normales" ---
              const Text(
                'Desafíos Diarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (desafios.diarios.isEmpty)
                const Text('No hay desafíos diarios disponibles.')
              else
                ...desafios.diarios.map(
                  (diario) => DesafioDiarioCard(diario: diario),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// -----------------------------------------------------------------------------------
// --- NUEVO: Widget Expandible para Eventos Especiales (Basado en tu imagen) ---
// -----------------------------------------------------------------------------------

class ExpandableSpecialEventCard extends StatefulWidget {
  final DesafioEspecial evento;
  final List<DesafioDiario> desafiosMensuales; // Contenido para la expansión

  const ExpandableSpecialEventCard({
    super.key,
    required this.evento,
    required this.desafiosMensuales,
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
    // Usamos el color de la primera imagen (un tono verde oscuro)
    final primaryColor = Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: primaryColor,
      child: Column(
        children: [
          // CABECERA (Siempre visible y control de expansión)
          InkWell(
            onTap: () {
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
                  // Barra de progreso y texto (similar a la segunda imagen)
                  const SizedBox(height: 10),
                  const Text(
                    'DESAFÍOS COMPLETADOS (0%)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Placeholder de progreso (adaptar con datos reales)
                  LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade300,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Título de la lista de desafíos
                  const Text(
                    'DESAFÍOS MENSUALES DISPONIBLES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Lista de Desafíos Mensuales (usando el contenido del listado diario)
                  if (widget.desafiosMensuales.isEmpty)
                    const Text(
                      'No hay desafíos para este evento.',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    ...widget.desafiosMensuales.map(
                      (desafio) => MonthlyChallengeItem(
                        desafio: desafio,
                        parentColor: primaryColor,
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
// --- NUEVO: Item para cada Desafío Mensual (dentro del expandible) ---
// -----------------------------------------------------------------------------------
class MonthlyChallengeItem extends StatelessWidget {
  final DesafioDiario desafio;
  final Color parentColor;
  const MonthlyChallengeItem({
    super.key,
    required this.desafio,
    required this.parentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Color.lerp(
        parentColor,
        Colors.black,
        0.2,
      ), // Tono ligeramente más oscuro
      child: ListTile(
        leading: const Icon(Icons.code, color: Colors.white),
        title: Text(
          desafio.titulo,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${desafio.recompensaExp} XP',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          // Navegar a la dinámica del reto específico
          context.go('/reto/${desafio.idReto}');
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------------
// --- Tarjeta para Desafíos Diarios "Normales" (Mantenida) ---
// -----------------------------------------------------------------------------------
class DesafioDiarioCard extends StatelessWidget {
  final DesafioDiario diario;
  const DesafioDiarioCard({super.key, required this.diario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: const Icon(Icons.quiz, color: Colors.green),
        title: Text(diario.titulo),
        subtitle: Text('${diario.recompensaExp} XP'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegación al distribuidor con el ID
          context.go('/reto/${diario.idReto}');
        },
      ),
    );
  }
}
// [FIN DEL ARCHIVO desafio_view.dart]