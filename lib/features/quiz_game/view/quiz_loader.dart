import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/quiz_game/provider/quiz_provider.dart'; // Ajusta la ruta
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_page.dart'; // Ajusta la ruta

class QuizLoaderPage extends ConsumerWidget {
  final String seccionId; // El ID de la sección que se va a jugar

  const QuizLoaderPage({super.key, required this.seccionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el proveedor de la familia pasándole el seccionId
    final quizDataAsync = ref.watch(quizProvider(seccionId));

    return quizDataAsync.when(
      // Cuando los datos están listos, muestra la página del quiz
      data: (mydata) {
        // 'mydata' es el objeto QuizData que creamos en el provider
        if (mydata.questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('No se encontraron preguntas para este reto.'),
            ),
          );
        }
        return QuizPage(mydata: mydata);
      },
      // Mientras carga, muestra un indicador
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1D25), // Color de fondo de tu app
        body: Center(child: CircularProgressIndicator()),
      ),
      // Si hay un error, muéstralo
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar el quiz: $err'),
          ),
        ),
      ),
    );
  }
}
