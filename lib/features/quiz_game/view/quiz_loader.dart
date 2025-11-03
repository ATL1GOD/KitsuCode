// [COMIENZO DEL ARCHIVO quiz_loader.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/quiz_game/provider/reto_provider.dart'; // <-- YA NO SE USA
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart';

// --- PASO 1: Mover la clase QuizData aquí ---
// (Esto ya lo tenías, sin cambios)
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
  // --- ¡MODIFICADO! ---
  // Ya no recibe 'retoId', recibe el JSON directamente.
  final Map<String, dynamic> challengeContent;

  const QuizLoaderPage({super.key, required this.challengeContent});
  // --- FIN MODIFICACIÓN ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- ¡MODIFICADO! ---
    // Se elimina el ref.watch(challengeProvider) y el challengeDataAsync.when()
    // Ahora trabajamos directamente con 'challengeContent'.
    // --- FIN MODIFICACIÓN ---

    // --- PASO 2: LÓGICA DE TRANSFORMACIÓN (Sin cambios) ---
    final List<dynamic> preguntasList = challengeContent['preguntas'] ?? [];

    final Map<String, String> mapaPreguntas = {};
    final Map<String, Map<String, dynamic>> mapaOpciones = {};
    final Map<String, String> mapaRespuestas = {};

    // (Tu lógica de 'for (var pregunta in preguntasList)' no cambia)
    for (var pregunta in preguntasList) {
      try {
        final key = pregunta['key'] as String;
        mapaPreguntas[key] = pregunta['pregunta'] as String;
        mapaRespuestas[key] = pregunta['respuesta'] as String;
        mapaOpciones[key] = Map<String, dynamic>.from(pregunta['opciones']);
      } catch (e) {
        print("Error parseando pregunta: $e");
      }
    }
    // --- FIN PASO 2 ---

    if (mapaPreguntas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No se encontraron preguntas válidas para este reto.'),
        ),
      );
    }

    final mydata = QuizData(
      questions: mapaPreguntas,
      options: mapaOpciones,
      answers: mapaRespuestas,
    );

    // Finalmente, devuelve la página del juego
    return QuizPage(mydata: mydata);
  }
}
// [FIN DEL ARCHIVO quiz_loader.dart]