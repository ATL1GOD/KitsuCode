// lib/features/puzzle_game/view/puzzle_loader_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';

// --- 1. DEFINIMOS EL LOADER DE PUZZLE ---
class PuzzleLoaderPage extends StatelessWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId; // (ej: "2")

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
          // --- (Tu lógica de override está perfecta) ---
          (ref) => PuzzleNotifier(
            challengeContent,
            int.parse(retoId), // Convierte "2" a 2
            ref,
          ),
        ),
      ],
      // 2. MOSTRAMOS LA VISTA DEL PUZZLE
      // --- ¡CAMBIO AQUÍ! ---
      // Quitamos 'const' para permitir que el widget
      // se reconstruya cuando el tema (lenguaje) cambie.
      child: PuzzleView(),
      // --- FIN CAMBIO ---
    );
  }
}