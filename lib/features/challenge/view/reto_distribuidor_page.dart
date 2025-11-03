// [COMIENZO DEL ARCHIVO reto_distribuidor_page.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa tu provider y TODOS tus loaders
import 'package:kitsucode/features/quiz_game/provider/reto_provider.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';
import 'package:kitsucode/features/quiz_game/view/placeholder_loader.dart';
import 'package:kitsucode/features/columnas_game/view/columnas_loader.dart';

class RetoDistribuidorPage extends ConsumerWidget {
  final String retoId;

  const RetoDistribuidorPage({super.key, required this.retoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int retoIdInt = int.tryParse(retoId) ?? 0;

    // 1. Llama al provider UNA SOLA VEZ para obtener el contenido del reto
    final challengeDataAsync = ref.watch(challengeProvider(retoIdInt));

    // 2. Muestra .when() para manejar los estados de carga
    return challengeDataAsync.when(
      data: (challengeContent) {
        // 3. Extrae el "tipo" de dinámica del JSON
        final String? tipo = challengeContent['tipo'] as String?;

        // 4. Decide qué Loader mostrar basado en el tipo
        switch (tipo) {
          case 'Quiz':
            // ¡Pasa el contenido ya cargado directamente al loader!
            return QuizLoaderPage(challengeContent: challengeContent);

          case 'Puzzle':
            // TODO: Cuando crees PuzzleLoader, haz que acepte challengeContent
            return PlaceholderLoader(retoId: retoId, dinamica: "Puzzle");

          case 'Relacion':
            return ColumnsLoader(
              challengeContent: challengeContent,
              retoId: retoId,
            );

          case 'Codigo':
            // TODO: Cuando crees CodeLoader, haz que acepte challengeContent
            return PlaceholderLoader(retoId: retoId, dinamica: "Código");

          // 5. Maneja casos desconocidos o erróneos
          default:
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: Tipo de reto "$tipo" no reconocido para el ID $retoId.',
                  ),
                ),
              ),
            );
        }
      },
      // 6. Muestra pantallas de carga y error mientras el provider trabaja
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1D25), // O tu color de fondo global
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error al Cargar')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${err.toString()}'),
          ),
        ),
      ),
    );
  }
}
// [FIN DEL ARCHIVO reto_distribuidor_page.dart]