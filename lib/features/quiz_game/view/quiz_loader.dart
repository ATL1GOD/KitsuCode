import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa el NUEVO provider de reto
import 'package:kitsucode/features/quiz_game/provider/reto_provider.dart';
import 'package:kitsucode/features/quiz_game/provider/quiz_provider.dart'; // Import QuizData class
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart'; // Ajusta la ruta

class QuizLoaderPage extends ConsumerWidget {
  // --- CORRECCIÓN IMPORTANTE ---
  // Ya no usamos seccionId, usamos retoId que viene de la ruta
  final String retoId;

  const QuizLoaderPage({super.key, required this.retoId});
  // --- FIN CORRECIÓN ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int retoIdInt = int.tryParse(retoId) ?? 0;
    // Observamos el NUEVO proveedor, pasándole el retoId
    final challengeDataAsync = ref.watch(challengeProvider(retoIdInt));

    return challengeDataAsync.when(
      data: (challengeContent) {
        // 'challengeContent' es el JSONB que leímos de 'contenido_reto'

        // 1. Validar que este reto sea realmente un 'Quiz'
        if (challengeContent['tipo'] != 'Quiz') {
          return Scaffold(
            appBar: AppBar(title: const Text('Error de Reto')),
            body: Center(
              child: Text(
                'Error: El contenido (ID: $retoId) no es un Quiz, es tipo "${challengeContent['tipo']}".',
              ),
            ),
          );
        }

        // --- 2. LÓGICA DE TRANSFORMACIÓN ---
        // Aquí transformas el JSON de 'contenido_reto' al formato
        // que tu 'QuizPage' (mydata) espera.

        final List<dynamic> preguntasJson = challengeContent['preguntas'] ?? [];

        final Map<String, String> mapaPreguntas = {};
        final Map<String, Map<String, dynamic>> mapaOpciones = {};
        final Map<String, String> mapaRespuestas = {};

        int i = 1;
        for (var pregunta in preguntasJson) {
          try {
            final key = i.toString();
            mapaPreguntas[key] = pregunta['pregunta_texto'] as String;
            mapaRespuestas[key] = pregunta['respuesta_correcta'] as String;
            // Asegurarse que las opciones se copien como Map<String, dynamic>
            mapaOpciones[key] = Map<String, dynamic>.from(pregunta['opciones']);
            i++;
          } catch (e) {
            print("Error parseando pregunta: $e");
            // Omitir pregunta mal formada
          }
        }

        if (mapaPreguntas.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text(
                'No se encontraron preguntas válidas para este reto.',
              ),
            ),
          );
        }

        // 3. Creamos el objeto QuizData que QuizPage espera
        final mydata = QuizData(
          questions: mapaPreguntas,
          options: mapaOpciones,
          answers: mapaRespuestas,
        );

        // 4. Enviamos los datos transformados a la página del Quiz
        return QuizPage(mydata: mydata);
        // --- FIN LÓGICA ---
      },

      // Mientras carga, muestra un indicador
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1D25), // Color de fondo de tu app
        body: Center(child: CircularProgressIndicator()),
      ),

      // Si hay un error, muéstralo
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
