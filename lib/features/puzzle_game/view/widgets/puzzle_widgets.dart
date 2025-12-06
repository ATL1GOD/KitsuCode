import 'package:flutter/material.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

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
          color:
              (isFilled
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest)
                  .withAlpha(isDragging ? 204 : 255),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isFilled ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1.0,
          ),
          boxShadow: (isFilled || isDragging)
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(100),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
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
        border: Border.all(color: colorScheme.primary, width: 2.0),
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

class DraggableOption extends StatelessWidget {
  final PuzzleOption option;
  final bool isFilled;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const DraggableOption({
    super.key,
    required this.option,
    this.isFilled = false,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<PuzzleOption>(
      data: option,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
      feedback: PuzzleChip(
        text: option.text,
        isFilled: isFilled,
        isDragging: true,
      ),

      childWhenDragging: isFilled
          ? const EmptyBlank()
          : Opacity(
              opacity: 0.0,
              child: PuzzleChip(text: option.text, isFilled: isFilled),
            ),

      child: PuzzleChip(text: option.text, isFilled: isFilled),
    );
  }
}

class DragTargetBlank extends StatelessWidget {
  final String blankId;
  final PuzzleOption? filledOption;
  final void Function(String, PuzzleOption) onOptionDropped;
  final String? draggingFromBlankId;
  final PuzzleOption? draggingOption;
  final Map<String, PuzzleOption?> allFilledBlanks;
  final void Function(String, PuzzleOption) onDragStarted;
  final VoidCallback onDragEnd;
  final String? hoveringOverBlankId;
  final void Function(String?) onHoverBlank;

  const DragTargetBlank({
    super.key,
    required this.blankId,
    required this.filledOption,
    required this.onOptionDropped,
    required this.draggingFromBlankId,
    required this.draggingOption,
    required this.allFilledBlanks,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.hoveringOverBlankId,
    required this.onHoverBlank,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool isSourceBlank = draggingFromBlankId == blankId;

    final bool isHoveringOverOtherBlank =
        hoveringOverBlankId != null && hoveringOverBlankId != blankId;
    final PuzzleOption? hoveringBlankOption = isHoveringOverOtherBlank
        ? allFilledBlanks[hoveringOverBlankId]
        : null;

    return DragTarget<PuzzleOption>(
      onMove: (details) {
        if (draggingFromBlankId != null) {
          onHoverBlank(blankId);
        }
      },
      onLeave: (data) {
        onHoverBlank(null);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isBeingDraggedOver = candidateData.isNotEmpty;
        final PuzzleOption? incomingOption = candidateData.isNotEmpty
            ? candidateData.first
            : null;

        if (isSourceBlank &&
            draggingOption != null &&
            draggingFromBlankId != null &&
            filledOption?.uniqueId == draggingOption?.uniqueId &&
            !isBeingDraggedOver) {
          if (hoveringBlankOption != null &&
              hoveringOverBlankId != null &&
              hoveringOverBlankId != blankId) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: colorScheme.tertiary.withOpacity(0.25),
                border: Border.all(color: colorScheme.tertiary, width: 3.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                hoveringBlankOption.text,
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            );
          }

          return const EmptyBlank();
        }

        if (filledOption == null) {
          if (isBeingDraggedOver && incomingOption != null) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: colorScheme.primary.withAlpha(51),
                border: Border.all(color: colorScheme.primary, width: 3.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                incomingOption.text,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            );
          }

          return const EmptyBlank();
        }

        if (isBeingDraggedOver &&
            incomingOption != null &&
            incomingOption.uniqueId != filledOption!.uniqueId) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: colorScheme.primary.withOpacity(0.25),
              border: Border.all(color: colorScheme.primary, width: 3.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              incomingOption.text,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          );
        }

        return DraggableOption(
          option: filledOption!,
          isFilled: true,
          onDragStarted: () => onDragStarted(blankId, filledOption!),
          onDragEnd: onDragEnd,
        );
      },
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onHoverBlank(null);
        onDragEnd();

        onOptionDropped(blankId, details.data);
      },
    );
  }
}

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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
