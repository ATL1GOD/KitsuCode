// lib/features/puzzle_game/view/puzzle_loader_page.dart (CORREGIDO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa el NUEVO provider y la VISTA
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';

// Este es el "Loader" que tu equipo espera.
// Sigue el patrón de 'QuizLoaderPage.dart'
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
    // 1. ANULAMOS (Override) el provider simple 'puzzleProvider'
    //    y le pasamos el contenido del reto (el JSON).
    return ProviderScope(
      overrides: [
        puzzleProvider.overrideWith(
          // Le pasamos el 'challengeContent' al constructor del Notifier
          (ref) => PuzzleNotifier(challengeContent),
        ),
      ],
      // 2. Mostramos tu PuzzleView
      //    PuzzleView ahora leerá el provider que acabamos de anular.
      child: const PuzzleView(), 
    );
  }
}