import 'package:flutter/material.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';

class PuzzleCodeArea extends StatelessWidget {
  final List<PuzzleLine> lines; 
  final Map<String, PuzzleOption?> filledBlanks;
  final void Function(String, PuzzleOption) onOptionDropped; 

  const PuzzleCodeArea({
    super.key,
    required this.lines,
    required this.filledBlanks,
    required this.onOptionDropped,
  });

  // --- 1. FUNCIÓN HELPER PARA LOS COLORES ---
  TextStyle _getStyleForToken(String highlight, TextStyle baseStyle, ColorScheme colorScheme) {
    switch (highlight) {
      case 'keyword': // p.ej. #include, if, return
        // Usa el color secundario del tema del lenguaje
        return baseStyle.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold);
      case 'type': // p.ej. int, void
        // Usa el color terciario del tema del lenguaje
        return baseStyle.copyWith(color: colorScheme.tertiary, fontWeight: FontWeight.bold);
      case 'string': // p.ej. "Es par", <stdio.h>
        // Usamos un color fijo (verde) para los strings
        return baseStyle.copyWith(color: Colors.green.shade600);
      case 'normal':
      default:
        return baseStyle; // Estilo normal (color onSurface)
    }
  }
  // --- FIN DE LA FUNCIÓN HELPER ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // --- 2. DEFINIMOS EL ESTILO BASE ---
    final baseStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontFamily: 'monospace',
          color: colorScheme.onSurface,
          height: 1.6,
        );

    return Container(
      width: double.infinity,
      // (Padding quitado en el paso anterior, ¡perfecto!)
      child: RichText(
        text: TextSpan(
          style: baseStyle, // Estilo base para todo
          children: lines.map((line) {

            // --- 3. LÓGICA DE RENDERIZADO MODIFICADA ---
            // Ahora leemos 'TokenLine' en lugar de 'CodeLine'
            if (line is TokenLine) {
              return TextSpan(
                text: line.text,
                // ¡Aplicamos el estilo dinámico!
                style: _getStyleForToken(line.highlight, baseStyle, colorScheme),
              );
            }
            // --- FIN DE LA MODIFICACIÓN ---

            if (line is BlankLine) {
              final blankId = line.id;
              final filledOption = filledBlanks[blankId];
              
              return WidgetSpan(
                alignment: PlaceholderAlignment.middle, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: DragTargetBlank(
                    blankId: blankId,
                    filledOption: filledOption,
                    onOptionDropped: onOptionDropped,
                  ),
                ),
              );
            }
            return const TextSpan(text: '');
          }).toList(),
        ),
      ),
    );
  }
}