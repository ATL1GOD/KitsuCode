// [COMIENZO DEL ARCHIVO /lib/features/quiz_game/view/widgets/result_page.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Importaciones Clave ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  final int marks;
  final int totalQuestions;
  final int durationInSeconds;
  final String retoId;

  const QuizResultPage({
    super.key,
    required this.marks,
    required this.totalQuestions,
    required this.durationInSeconds,
    required this.retoId,
  });

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    // Enviamos el resultado tan pronto como se carga la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitResult();
    });
  }

  Future<void> _submitResult() async {
    if (_hasSubmitted) return;
    setState(() {
      _hasSubmitted = true;
    });

    // 1. Determinar si fue exitoso (puedes cambiar esta lógica)
    //    Aquí asumimos que "completado" es obtener al menos una respuesta correcta.
    final bool fueExitoso = widget.marks > 0;

    // 2. Parsear el retoId
    final int retoIdAsInt;
    try {
      retoIdAsInt = int.parse(widget.retoId);
    } catch (e) {
      debugPrint("Error: retoId no es un número válido: ${widget.retoId}");
      return;
    }

    // 3. Enviar el intento
    try {
      final repository = ref.read(challengeRepositoryProvider);
      await repository.submitChallengeAttempt(
        retoId: retoIdAsInt,
        fueExitoso: fueExitoso,
        tiempoQueTardo: widget.durationInSeconds,
      );

      // 4. Refrescar las estadísticas (vidas, etc.) y el ranking
      ref.read(appBarProvider.notifier).fetchStats();
      ref.invalidate(globalRankingProvider);
    } catch (e) {
      debugPrint("Error al enviar intento de quiz: $e");
      // Opcional: mostrar un SnackBar si falla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar tu resultado: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool didPass = widget.marks > 0;
    final String title = didPass ? "¡Reto Completado!" : "¡Sigue intentando!";

    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Tu Puntuación",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              "${widget.marks}", // Puntos ganados
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: didPass ? Colors.green : Colors.red,
              ),
            ),
            Text(
              "de ${widget.totalQuestions * 5} puntos posibles",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                // --- ¡LÓGICA CLAVE AL CONTINUAR! ---

                // 1. Si el reto fue exitoso, invalidamos el mapa
                if (didPass) {
                  ref.invalidate(homeViewModelProvider);
                }

                // 2. Salir de la pantalla de resultados
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Continuar", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
// [FIN DEL ARCHIVO /lib/features/quiz_game/view/widgets/result_page.dart]