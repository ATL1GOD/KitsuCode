// lib/features/quiz_game/view/quiz_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart';

// --- PASO 1: Mover la clase QuizData aquí ---
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
  // Ahora también recibe 'retoId'
  final Map<String, dynamic> challengeContent;
  final String retoId; // <-- ¡AÑADIDO!

  const QuizLoaderPage({
    super.key, 
    required this.challengeContent,
    required this.retoId, // <-- ¡AÑADIDO!
  });
  // --- FIN MODIFICACIÓN ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- LÓGICA DE TRANSFORMACIÓN ---
    final List<dynamic> preguntasList = challengeContent['preguntas'] ?? [];

    final Map<String, String> mapaPreguntas = {};
    final Map<String, Map<String, dynamic>> mapaOpciones = {};
    final Map<String, String> mapaRespuestas = {};

    for (var pregunta in preguntasList) {
      try {
        final key = pregunta['key'] as String;
        mapaPreguntas[key] = pregunta['pregunta'] as String;
        mapaRespuestas[key] = pregunta['respuesta'] as String;
        mapaOpciones[key] = Map<String, dynamic>.from(pregunta['opciones']);
      } catch (e) {
        // Corregido para usar debugPrint
        debugPrint("Error parseando pregunta: $e"); 
      }
    }
    // --- FIN LÓGICA ---

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

    // --- ¡CORREGIDO! ---
    // Ahora le pasamos el retoId a QuizPage
    return QuizPage(
      mydata: mydata,
      retoId: retoId, // <-- ¡AÑADIDO!
    );
  }
}