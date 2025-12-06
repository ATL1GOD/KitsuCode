import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_view.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

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

  factory QuizData.fromJson(Map<String, dynamic> challengeContent) {
    List<dynamic> preguntasList = challengeContent['preguntas'] ?? [];

    if (preguntasList.isNotEmpty) {
      final random = Random();

      final randomIndex = random.nextInt(preguntasList.length);

      preguntasList = [preguntasList[randomIndex]];
    }

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
  final String nivelId;

  const QuizLoaderPage({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuizData mydata;
    try {
      mydata = QuizData.fromJson(challengeContent);
    } catch (e) {
      debugPrint("Error creando QuizData: $e");
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Error al cargar el reto.')),
      );
    }

    if (mydata.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No se encontraron preguntas válidas para este reto.'),
        ),
      );
    }

    return QuizPage(mydata: mydata, retoId: retoId, nivelId: nivelId);
  }
}
