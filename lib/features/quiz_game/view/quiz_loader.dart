// lib/features/quiz_game/view/quiz_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;

// --- REFACTOR (PASO 1): Usar un 'factory constructor' ---
// Esto encapsula la lógica de "cómo crear un QuizData desde JSON"
// dentro de la propia clase QuizData, en lugar de hacerlo en el Widget.
class QuizData {
  final Map<String, String> questions;
  final Map<String, Map<String, dynamic>> options;
  final Map<String, String> answers;
  final int totalQuestions;
  final List<RecursoModel> recursos;

  QuizData({
    required this.questions,
    required this.options,
    required this.answers,
    required this.recursos,
  }) : totalQuestions = questions.length;

  // --- ¡NUEVO CONSTRUCTOR! ---
  factory QuizData.fromChallengeContent(Map<String, dynamic> challengeContent) {
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

    final List<dynamic> recursosJson =
        challengeContent['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return QuizData(
      questions: mapaPreguntas,
      options: mapaOpciones,
      answers: mapaRespuestas,
      recursos: recursosList,
    );
  }
}

class QuizLoaderPage extends ConsumerWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;
  final String nivelId; // ← ¡AÑADIDO!

  const QuizLoaderPage({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId, // ← ¡AÑADIDO!
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- REFACTOR (PASO 2): Lógica de build simplificada ---
    // Toda la lógica de parseo ahora vive en el 'factory constructor'.
    // El widget 'build' ahora solo se preocupa de construir.
    final QuizData mydata;
    try {
      mydata = QuizData.fromChallengeContent(challengeContent);
    } catch (e) {
      debugPrint("Error creando QuizData: $e");
      // Si falla la creación, mostramos la pantalla de error genérica.
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Error al cargar el reto.')),
      );
    }

    // El 'factory constructor' se encargó de las listas vacías,
    // así que solo necesitamos comprobar el resultado.
    if (mydata.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No se encontraron preguntas válidas para este reto.'),
        ),
      );
    }

    // Si todo está bien, pasamos el objeto 'mydata' ya construido.
    return QuizPage(
      mydata: mydata, 
      retoId: retoId,
      nivelId: nivelId, // ← ¡AÑADIDO!
    );
  }
}