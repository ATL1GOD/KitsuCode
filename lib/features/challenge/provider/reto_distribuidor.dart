// [COMIENZO DEL ARCHIVO reto_distribuidor_page.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa tu provider y TODOS tus loaders
import 'package:kitsucode/features/challenge/provider/reto_provider.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';
import 'package:kitsucode/features/quiz_game/view/placeholder_loader.dart';
import 'package:kitsucode/features/columnas_game/view/columnas_loader.dart';
import 'package:kitsucode/features/codigo_game/view/codigo_loader.dart';

class RetoDistribuidorPage extends ConsumerWidget {
  final String retoId;

  const RetoDistribuidorPage({super.key, required this.retoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int retoIdInt = int.tryParse(retoId) ?? 0;

    final challengeDataAsync = ref.watch(challengeProvider(retoIdInt));

    return challengeDataAsync.when(
      data: (challengeData) {
        // 1. Extrae los 2 datos del objeto ChallengeData
        final String tipo = challengeData.dinamicaNombre;
        final Map<String, dynamic> challengeContent = challengeData.contenido;
        // final String titulo = ... // <-- CAMBIO: LÍNEA ELIMINADA

        // 2. Pasa solo el contenido (y retoId donde se necesite)
        switch (tipo) {
          case 'Quiz':
            return QuizLoaderPage(
              challengeContent: challengeContent,
              // titulo: titulo, // <-- CAMBIO: LÍNEA ELIMINADA
            );

          case 'Puzzle':
            return PlaceholderLoader(
              retoId: retoId,
              dinamica: "Puzzle",
              // titulo: titulo, // <-- CAMBIO: LÍNEA ELIMINADA
            );

          case 'Relacion':
            return ColumnsLoader(
              challengeContent: challengeContent,
              retoId: retoId,
              // titulo: titulo, // <-- CAMBIO: LÍNEA ELIMINADA
            );

          case 'Codigo':
            return CodigoLoader(
              challengeContent: challengeContent,
              retoId: retoId,
            );

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
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1D25),
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