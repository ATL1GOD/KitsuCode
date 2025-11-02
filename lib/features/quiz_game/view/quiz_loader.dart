import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/provider/reto_provider.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart';

// --- PASO 1: Mover la clase QuizData aquí ---
// (Esta clase estaba en el 'quiz_provider.dart' obsoleto)
class QuizData {
  final Map<String, String> questions;
  final Map<String, Map<String, dynamic>> options;
  final Map<String, String> answers;
  final int totalQuestions;

  QuizData({
    required this.questions,
    required this.options,
    required this.answers,
  }) : totalQuestions = questions.length;
}
// --- FIN PASO 1 ---

class QuizLoaderPage extends ConsumerWidget {
  final String retoId;

  const QuizLoaderPage({super.key, required this.retoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int retoIdInt = int.tryParse(retoId) ?? 0;
    final challengeDataAsync = ref.watch(challengeProvider(retoIdInt));

    return challengeDataAsync.when(
      data: (challengeContent) {
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

        // --- PASO 2: LÓGICA DE TRANSFORMACIÓN CORREGIDA ---
        final List<dynamic> preguntasList = challengeContent['preguntas'] ?? [];

        final Map<String, String> mapaPreguntas = {};
        final Map<String, Map<String, dynamic>> mapaOpciones = {};
        final Map<String, String> mapaRespuestas = {};

        // Ya no usamos 'i', usamos el 'key' que viene del JSON
        for (var pregunta in preguntasList) {
          try {
            // ¡CORRECCIÓN! Leemos las claves correctas del JSON
            final key = pregunta['key'] as String;
            mapaPreguntas[key] = pregunta['pregunta'] as String;
            mapaRespuestas[key] = pregunta['respuesta'] as String;
            mapaOpciones[key] = Map<String, dynamic>.from(pregunta['opciones']);
          } catch (e) {
            // Esta impresión te dirá si alguna pregunta en tu JSON está mal formada
            print("Error parseando pregunta: $e");
          }
        }
        // --- FIN PASO 2 ---

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

        final mydata = QuizData(
          questions: mapaPreguntas,
          options: mapaOpciones,
          answers: mapaRespuestas,
        );

        return QuizPage(mydata: mydata);
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
