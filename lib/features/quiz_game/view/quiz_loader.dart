// lib/features/quiz_game/view/quiz_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart';
// --- NUEVO: Importación para el modelo de recursos ---
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

// --- PASO 1: Mover la clase QuizData aquí (¡MODIFICADA!) ---
class QuizData {
  final Map<String, String> questions;
  final Map<String, Map<String, dynamic>> options;
  final Map<String, String> answers;
  final int totalQuestions;
  // --- NUEVO ---
  final List<RecursoModel> recursos;

  QuizData({
    required this.questions,
    required this.options,
    required this.answers,
    required this.recursos, // <-- AÑADIDO
  }) : totalQuestions = questions.length;
}
// --- FIN PASO 1 ---

class QuizLoaderPage extends ConsumerWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;

  const QuizLoaderPage({
    super.key,
    required this.challengeContent,
    required this.retoId,
  });

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
        debugPrint("Error parseando pregunta: $e");
      }
    }
    // --- FIN LÓGICA ---

    // --- NUEVA LÓGICA DE RECURSOS ---
    // (Lee los recursos que inyectamos desde 'reto_distribuidor.dart')
    final List<dynamic> recursosJson =
        challengeContent['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();
    // --- FIN NUEVA LÓGICA ---

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
      recursos: recursosList, // <-- AÑADIDO
    );

    return QuizPage(mydata: mydata, retoId: retoId);
  }
}
