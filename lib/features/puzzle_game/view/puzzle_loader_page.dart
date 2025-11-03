import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';

// --- 1. DEFINIMOS EL LOADER DE PUZZLE ---
class PuzzleLoaderPage extends StatelessWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;

  const PuzzleLoaderPage({
    super.key,
    required this.challengeContent,
    required this.retoId,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ANULAMOS EL PROVIDER DE PUZZLE PARA INYECTAR NUESTRO NOTIFIER
    return ProviderScope(
      overrides: [
        puzzleProvider.overrideWith(
          // Le pasamos el 'challengeContent' al constructor del Notifier
          (ref) => PuzzleNotifier(challengeContent),
        ),
      ],
      // 2. MOSTRAMOS LA VISTA DEL PUZZLE
      child: const PuzzleView(),
    );
  }
}