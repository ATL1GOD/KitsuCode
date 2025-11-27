// features/desafio/presentation/widgets/expandable_special_event_card.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'special_event_card_header.dart';
import 'special_event_expandable_content.dart';

class ExpandableSpecialEventCard extends StatefulWidget {
  final DesafioEspecial evento;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Color base normal (Verde/Azul/etc dependiendo del tema)
    final primaryColor = brightness == Brightness.dark
        ? widget.evento.colorOscuro
        : widget.evento.colorClaro;

    final totalChallenges = widget.desafiosMensuales.length;
    final completedChallenges = widget.completedRetoIds.length;
    final double progress = totalChallenges == 0
        ? 0.0
        : completedChallenges / totalChallenges;

    // Texto personalizado si se completó
    final progressTitle = widget.isParentCompleted
        ? '¡Evento Completado!'
        : (totalChallenges > 0
              ? 'Completa $totalChallenges desafíos'
              : 'Sin desafíos definidos');

    // --- ESTÉTICA MEJORADA: Gradiente Dorado si está completo ---
    final decoration = widget.isParentCompleted
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFA000), // Ámbar intenso
                Color(0xFFF57C00), // Naranja oscuro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: decoration, // Usamos Container para aplicar el gradiente
      child: Material(
        color: Colors.transparent, // Transparente para ver el gradiente
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // CABECERA (Ahora SIEMPRE es clickeable para expandir)
            // -----------------------------------------------------------------
            InkWell(
              // 🔥 CLAVE: Eliminamos la condición null. Siempre permite expandir.
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              splashColor: Colors.white.withOpacity(0.2),
              child: SpecialEventCardHeader(
                evento: widget.evento,
                isParentCompleted: widget.isParentCompleted,
                progressTitle: progressTitle,
                completedChallenges: completedChallenges,
                totalChallenges: totalChallenges,
                progress: progress,
                isExpanded: _isExpanded,
                desafiosMensuales: widget.desafiosMensuales,
                completedRetoIds: widget.completedRetoIds,
                // Si es dorado, pasamos un naranja oscuro para los textos internos
                primaryColor: widget.isParentCompleted
                    ? const Color(0xFFE65100)
                    : primaryColor,
              ),
            ),

            // -----------------------------------------------------------------
            // CONTENIDO EXPANDIBLE
            // -----------------------------------------------------------------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: animation,
                    curve: Curves.fastOutSlowIn,
                  ),
                  axis: Axis.vertical,
                  child: child,
                );
              },
              child: _isExpanded
                  ? SpecialEventExpandableContent(
                      key: const ValueKey('expanded_content'),
                      desafiosMensuales: widget.desafiosMensuales,
                      completedRetoIds: widget.completedRetoIds,
                      // Ajustamos color de items hijos
                      parentColor: widget.isParentCompleted
                          ? Colors.white
                          : primaryColor,
                    )
                  : Container(key: const ValueKey('collapsed_content')),
            ),
          ],
        ),
      ),
    );
  }
}
