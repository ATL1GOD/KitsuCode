import 'package:flutter/material.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';

class PuzzleCodeArea extends StatefulWidget {
  final List<PuzzleLine> lines;
  final Map<String, PuzzleOption?> filledBlanks;
  final void Function(String, PuzzleOption) onOptionDropped;

  const PuzzleCodeArea({
    super.key,
    required this.lines,
    required this.filledBlanks,
    required this.onOptionDropped,
  });

  @override
  State<PuzzleCodeArea> createState() => _PuzzleCodeAreaState();
}

class _PuzzleCodeAreaState extends State<PuzzleCodeArea> {
  // Rastrear qué chip está siendo arrastrado y desde dónde
  String? _draggingFromBlankId;
  PuzzleOption? _draggingOption;
  bool _isDragging = false; // Prevenir múltiples llamadas a onDragStarted
  String? _hoveringOverBlankId; // Nuevo: rastrear sobre qué blank está el cursor

  void _onDragStarted(String blankId, PuzzleOption option) {
    if (_isDragging) return; // Ya estamos arrastrando, ignorar
    setState(() {
      _draggingFromBlankId = blankId;
      _draggingOption = option;
      _isDragging = true;
    });
  }

  void _onDragEnd() {
    // Usar un pequeño delay para asegurar que el estado se limpie después del drop
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _draggingFromBlankId = null;
          _draggingOption = null;
          _isDragging = false;
          _hoveringOverBlankId = null;
        });
      }
    });
  }

  void _onHoverBlank(String? blankId) {
    if (_hoveringOverBlankId != blankId) {
      setState(() {
        _hoveringOverBlankId = blankId;
      });
    }
  }

  // --- 1. FUNCIÓN HELPER PARA LOS COLORES ---
  TextStyle _getStyleForToken(
    String highlight,
    TextStyle baseStyle,
    ColorScheme colorScheme,
  ) {
    switch (highlight) {
      case 'keyword': // p.ej. #include, if, return
        // Usa el color secundario del tema del lenguaje
        return baseStyle.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.bold,
        );
      case 'type': // p.ej. int, void
        // Usa el color terciario del tema del lenguaje
        return baseStyle.copyWith(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.bold,
        );
      case 'string': // p.ej. "Es par", <stdio.h>
        // Usamos un color fijo (verde) para los strings
        return baseStyle.copyWith(color: Colors.green.shade600);
      case 'normal':
      default:
        return baseStyle; // Estilo normal (color onSurface)
    }
  }
  // fin de la función helper

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // --- 2. DEFINIMOS EL ESTILO BASE
    final baseStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontFamily: 'monospace',
      color: colorScheme.onSurface,
      height: 1.6,
    );

    return SizedBox(
      width: double.infinity,
      // --- ALTURA AUTOMÁTICA ---
      child: RichText(
        text: TextSpan(
          style: baseStyle, // Estilo base para todo
          children: widget.lines.map((line) {
            // --- 3. LÓGICA DE RENDERIZADO MODIFICADA
            if (line is TokenLine) {
              return TextSpan(
                text: line.text,
                // ¡Aplicamos el estilo dinámico!
                style: _getStyleForToken(
                  line.highlight,
                  baseStyle,
                  colorScheme,
                ),
              );
            }
            // Lógica para BlankLine

            if (line is BlankLine) {
              final blankId = line.id;
              final filledOption = widget.filledBlanks[blankId];

              return WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: DragTargetBlank(
                    blankId: blankId,
                    filledOption: filledOption,
                    onOptionDropped: widget.onOptionDropped,
                    draggingFromBlankId: _draggingFromBlankId,
                    draggingOption: _draggingOption,
                    allFilledBlanks: widget.filledBlanks,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                    hoveringOverBlankId: _hoveringOverBlankId,
                    onHoverBlank: _onHoverBlank,
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
