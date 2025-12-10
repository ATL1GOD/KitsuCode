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
  String? _draggingFromBlankId;
  PuzzleOption? _draggingOption;
  bool _isDragging = false;
  String? _hoveringOverBlankId;

  void _onDragStarted(String blankId, PuzzleOption option) {
    if (_isDragging) return;
    setState(() {
      _draggingFromBlankId = blankId;
      _draggingOption = option;
      _isDragging = true;
    });
  }

  void _onDragEnd() {
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

  TextStyle _getStyleForToken(
    String highlight,
    TextStyle baseStyle,
    ColorScheme colorScheme,
  ) {
    switch (highlight) {
      case 'keyword':
        return baseStyle.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.bold,
        );
      case 'type':
        return baseStyle.copyWith(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.bold,
        );
      case 'string':
        return baseStyle.copyWith(color: Colors.green.shade600);
      case 'normal':
      default:
        return baseStyle;
    }
  }

  bool _shouldBreakLine(int index) {
    if (index == 0) return false;

    final currentLine = widget.lines[index];
    final prevLine = widget.lines[index - 1];

    if (currentLine is BlankLine) {
      if (prevLine is TokenLine) {
        final text = prevLine.text.trim();
        if (text.endsWith(';') || text.endsWith('}') || text.endsWith('{')) {
          return true;
        }
      }
    }

    if (prevLine is BlankLine && currentLine is TokenLine) {
       return false; 
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontFamily: 'monospace',
          color: colorScheme.onSurface,
          height: 1.6,
        );

    List<InlineSpan> textSpans = [];

    for (int i = 0; i < widget.lines.length; i++) {
      final line = widget.lines[i];

      if (_shouldBreakLine(i)) {
        textSpans.add(const TextSpan(text: '\n'));
      }

      if (line is TokenLine) {
        textSpans.add(TextSpan(
          text: line.text,
          style: _getStyleForToken(
            line.highlight,
            baseStyle,
            colorScheme,
          ),
        ));
      } else if (line is BlankLine) {
        final blankId = line.id;
        final filledOption = widget.filledBlanks[blankId];

        textSpans.add(WidgetSpan(
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
        ));
      }
    }

    return SizedBox(
      width: double.infinity,
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: textSpans,
        ),
      ),
    );
  }
}