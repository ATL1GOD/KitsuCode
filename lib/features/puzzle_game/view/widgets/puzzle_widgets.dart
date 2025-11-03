import 'package:flutter/material.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

// --- 1. PuzzleChip 
class PuzzleChip extends StatelessWidget {
  final String text;
  final bool isFilled;
  final bool isDragging;

  const PuzzleChip({
    super.key,
    required this.text,
    this.isFilled = false,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material( 
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: (isFilled
                  ? colorScheme.primaryContainer 
                  : colorScheme.surfaceContainerHighest)
              .withAlpha(isDragging ? 204 : 255),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isFilled ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1.0, 
          ),
          boxShadow: (isFilled || isDragging) ? null : [ 
            BoxShadow(
              color: colorScheme.primary.withAlpha(100), 
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 4), // Sombra "3D"
            )
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isFilled 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

// --- 2. EmptyBlank 
class EmptyBlank extends StatelessWidget {
  final bool isHighlighted; 
  const EmptyBlank({super.key, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 60,
      height: 42, 
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHighlighted 
          ? colorScheme.primaryContainer.withAlpha(128)
          : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all( 
          color: colorScheme.primary, 
          width: 2.0,
        ),
      ),
      child: Text(
        "...",
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

// --- 3. DraggableOption 
class DraggableOption extends StatelessWidget {
  final PuzzleOption option;
  final bool isFilled;

  const DraggableOption({
    super.key,
    required this.option,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<PuzzleOption>(
      data: option, 
      feedback: PuzzleChip(
        text: option.text,
        isFilled: isFilled,
        isDragging: true, 
      ),
      
      // 'childWhenDragging' es lo que se queda atrás.
      childWhenDragging: isFilled 
        ? const EmptyBlank() // Si estaba en un hueco, deja un hueco.
        : Opacity( // Si estaba en el banco...
            opacity: 0.0, // invisible para evitar "saltos" visuales
            child: PuzzleChip( // pero mantenemos el tamaño
              text: option.text,
              isFilled: isFilled,
            ),
          ),
      // fin de 'childWhenDragging'
          
      child: PuzzleChip(
        text: option.text,
        isFilled: isFilled,
      ),
    );
  }
}

// --- 4. DragTargetBlank 
class DragTargetBlank extends StatelessWidget {
  final String blankId;
  final PuzzleOption? filledOption;
  final void Function(String, PuzzleOption) onOptionDropped;

  const DragTargetBlank({
    super.key,
    required this.blankId,
    required this.filledOption,
    required this.onOptionDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PuzzleOption>(
      builder: (context, candidateData, rejectedData) {
        if (filledOption == null) {
          return EmptyBlank(
            isHighlighted: candidateData.isNotEmpty, 
          );
        }
        return DraggableOption(
          option: filledOption!,
          isFilled: true,
        );
      },
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onOptionDropped(blankId, details.data);
      },
    );
  }
}

// --- 5. PuzzleBottomBar
class PuzzleBottomBar extends StatelessWidget {
  final bool isButtonEnabled;
  final VoidCallback onCheckPressed;

  const PuzzleBottomBar({
    super.key,
    required this.isButtonEnabled,
    required this.onCheckPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12, 
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled 
            ? colorScheme.secondary
            : colorScheme.surfaceContainerHighest,
          foregroundColor: isButtonEnabled
            ? colorScheme.onSecondary
            : colorScheme.outline,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: isButtonEnabled ? onCheckPressed : null, 
        child: const Text(
          'COMPROBAR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}