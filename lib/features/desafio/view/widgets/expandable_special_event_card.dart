// features/desafio/presentation/widgets/expandable_special_event_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // IMPORTANTE
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'special_event_card_header.dart';
import 'special_event_expandable_content.dart';

// 1. CREAMOS EL PROVIDER PARA CONTROLAR EL ESTADO DESDE AFUERA
final specialEventExpandedProvider = StateProvider<bool>((ref) => false);

// 2. CAMBIAMOS A ConsumerStatefulWidget
class ExpandableSpecialEventCard extends ConsumerStatefulWidget {
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
  ConsumerState<ExpandableSpecialEventCard> createState() =>
      _ExpandableSpecialEventCardState();
}

class _ExpandableSpecialEventCardState
    extends ConsumerState<ExpandableSpecialEventCard> {
  // YA NO NECESITAMOS bool _isExpanded AQUÍ LOCALMENTE

  @override
  Widget build(BuildContext context) {
    // 3. LEEMOS EL ESTADO DEL PROVIDER
    final isExpanded = ref.watch(specialEventExpandedProvider);

    final brightness = Theme.of(context).brightness;

    final primaryColor = brightness == Brightness.dark
        ? widget.evento.colorOscuro
        : widget.evento.colorClaro;

    final totalChallenges = widget.desafiosMensuales.length;
    final completedChallenges = widget.completedRetoIds.length;
    final double progress = totalChallenges == 0
        ? 0.0
        : completedChallenges / totalChallenges;

    final progressTitle = widget.isParentCompleted
        ? '¡Evento Completado!'
        : (totalChallenges > 0
              ? 'Completa $totalChallenges desafíos'
              : 'Sin desafíos definidos');

    final decoration = widget.isParentCompleted
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA000), Color(0xFFF57C00)],
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
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                // 4. LÓGICA DE INTERACCIÓN
                final current = ref.read(specialEventExpandedProvider);

                if (!current) {
                  // Si vamos a EXPANDIR, cerramos el teclado
                  FocusScope.of(context).unfocus();
                }

                // Invertimos el valor en el provider global
                ref.read(specialEventExpandedProvider.notifier).state =
                    !current;
              },
              splashColor: Colors.white.withOpacity(0.2),
              child: SpecialEventCardHeader(
                evento: widget.evento,
                isParentCompleted: widget.isParentCompleted,
                progressTitle: progressTitle,
                completedChallenges: completedChallenges,
                totalChallenges: totalChallenges,
                progress: progress,
                isExpanded: isExpanded, // Usamos la variable del provider
                desafiosMensuales: widget.desafiosMensuales,
                completedRetoIds: widget.completedRetoIds,
                primaryColor: widget.isParentCompleted
                    ? const Color(0xFFE65100)
                    : primaryColor,
              ),
            ),

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
              // Usamos la variable del provider para decidir qué mostrar
              child: isExpanded
                  ? SpecialEventExpandableContent(
                      key: const ValueKey('expanded_content'),
                      desafiosMensuales: widget.desafiosMensuales,
                      completedRetoIds: widget.completedRetoIds,
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
