import 'package:flutter/material.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';

class PuzzleOptionsArea extends StatelessWidget {
  final List<PuzzleOption> availableOptions;
  final void Function(PuzzleOption) onOptionDropped; 

  const PuzzleOptionsArea({
    super.key,
    required this.availableOptions,
    required this.onOptionDropped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<PuzzleOption>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          // --- ¡QUITAMOS LA ALTURA FIJA! ---
          // La altura ahora será automática
          constraints: const BoxConstraints(minHeight: 120), 
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            // ... (la decoración del "banco" sigue igual)
            color: candidateData.isNotEmpty 
              ? colorScheme.primaryContainer.withAlpha(128) 
              : colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.primary.withAlpha(100), 
                width: 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ]
          ),
          
          // --- ¡REEMPLAZAMOS 'SingleChildScrollView' POR 'Wrap'! ---
          child: Wrap(
            spacing: 12.0, // Espacio horizontal entre chips
            runSpacing: 12.0, // Espacio vertical entre líneas de chips
            alignment: WrapAlignment.center, // ¡Centra las opciones!
            children: availableOptions.map((option) {
              return DraggableOption(
                option: option,
                isFilled: false,
              );
            }).toList(),
          ),
          // --- FIN DEL REEMPLAZO ---
        );
      },
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onOptionDropped(details.data);
      },
    );
  }
}