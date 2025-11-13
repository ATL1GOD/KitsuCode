// features/desafio/presentation/widgets/expandable_special_event_card.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart'; // Asumiendo que aquí están los modelos (DesafioEspecial, RetoIndividual)
import 'special_event_card_header.dart';
import 'special_event_expandable_content.dart';

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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    // Lógica de progreso (se queda aquí porque es necesaria para ambos hijos)
    final totalChallenges = widget.desafiosMensuales.length;
    final completedChallenges = widget.completedRetoIds.length;
    final double progress = totalChallenges == 0
        ? 0.0
        : completedChallenges / totalChallenges;
    final progressTitle = totalChallenges > 0
        ? 'Completa ${totalChallenges} desafíos'
        : 'Sin desafíos definidos';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: primaryColor,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // -----------------------------------------------------------------
          // CABECERA (Delegada a su propio widget)
          // -----------------------------------------------------------------
          InkWell(
            onTap: widget.isParentCompleted
                ? null
                : () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
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
              primaryColor: primaryColor,
            ),
          ),

          // -----------------------------------------------------------------------------------
          // CONTENIDO EXPANDIBLE (Delegado a su propio widget)
          // -----------------------------------------------------------------------------------
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
                    parentColor: primaryColor,
                  )
                : Container(key: const ValueKey('collapsed_content')),
          ),
        ],
      ),
    );
  }
}
