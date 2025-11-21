// lib/features/puzzle_game/view/puzzle_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_code_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_instruction_card.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_options_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';
// AÑADIR ESTA LÍNEA
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:animate_do/animate_do.dart';

// --- MODIFICACIÓN: Importación de tu snackbar personalizado ---
import 'package:kitsucode/shared/snackbar/snackbar.dart';
// --- FIN MODIFICACIÓN ---

// --- ¡CAMBIO 1! (Importaciones para el Tema y el Lenguaje) ---
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
// --- FIN CAMBIO 1 ---

// --- NUEVO: Importaciones para el repositorio, modelo y ranking ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';
// --- FIN NUEVO ---
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

// --- 1. DEFINIMOS LA VISTA DEL PUZZLE ---
class PuzzleView extends ConsumerWidget {
  const PuzzleView({super.key});

  // --- ¡CAMBIO 2! (Función Helper para obtener el Tema) ---
  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (langName.toLowerCase().trim()) {
      case 'python':
        return isDark ? AppThemes.pythonDarkTheme : AppThemes.pythonTheme;
      case 'c':
        return isDark ? AppThemes.cDarkTheme : AppThemes.cTheme;
      case 'java':
        return isDark ? AppThemes.javaDarkTheme : AppThemes.javaTheme;
      default:
        // Fallback al tema principal si no se reconoce el lenguaje
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
  }
  // --- FIN CAMBIO 2 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- ¡CAMBIO 3! (Obtener el tema del lenguaje actual) ---
    final appBarState = ref.watch(appBarProvider);

    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness, // Mantenemos el modo claro/oscuro
    );

    final colorScheme = challengeTheme.colorScheme;
    // --- FIN CAMBIO 3 ---

    final puzzleState = ref.watch(puzzleProvider);
    final puzzleNotifier = ref.read(puzzleProvider.notifier);

    // --- ¡CAMBIO 4! (MANEJO DE ESTADOS ¡AHORA FUNCIONA!) ---
    if (puzzleState.isLoading) {
      return Theme(
        data: challengeTheme,
        child: Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (puzzleState.error != null) {
      return Theme(
        data: challengeTheme,
        child: Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
            child: Text("Error al cargar el reto: ${puzzleState.error}"),
          ),
        ),
      );
    }
    // --- FIN CAMBIO 4 ---

    final challenge = puzzleState.challenge!;
    final bool isPuzzleComplete = !puzzleState.filledBlanks.containsValue(null);

    // --- ¡AÑADE ESTO! ---
    // Calculamos el progreso basado en los espacios llenos
    final int totalBlanks = puzzleState.filledBlanks.length;
    final int filledCount = puzzleState.filledBlanks.values
        .where((v) => v != null)
        .length;

    // Evitamos división por cero
    final double progress = (totalBlanks > 0)
        ? (filledCount / totalBlanks)
        : 0.0;
    // --- FIN DEL BLOQUE AÑADIDO ---

    // --- ¡CAMBIO 5! (Envolver el Scaffold principal en el Tema) ---
    return Theme(
      data: challengeTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: ChallengeAppBar2(
          progress: progress,
          onClose: () {
            showExitDialog(context, ref);
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 300),
                        child: PuzzleInstructionCard(
                          text: challenge.instruction,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeIn(
                        duration: const Duration(milliseconds: 300),
                        delay: const Duration(milliseconds: 150),
                        child: PuzzleCodeArea(
                          lines: challenge.lines,
                          filledBlanks: puzzleState.filledBlanks,
                          onOptionDropped: (blankId, option) {
                            puzzleNotifier.onOptionDroppedOnBlank(
                              blankId,
                              option,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SlideInUp(
              duration: const Duration(milliseconds: 250),
              from: 100,
              child: PuzzleOptionsArea(
                availableOptions: puzzleState.availableOptions,
                onOptionDropped: (option) {
                  puzzleNotifier.onOptionDroppedOnBank(option);
                },
              ),
            ),
          ],
        ),

        // --- ¡¡AQUÍ ESTÁ LA MAGIA!! ---
        bottomNavigationBar: PuzzleBottomBar(
          isButtonEnabled: isPuzzleComplete,
          onCheckPressed: () {
            puzzleNotifier.checkSolution(); // Esto solo actualiza el estado
            final esCorrecto =
                ref.read(puzzleProvider).status == PuzzleStatus.correct;

            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              // ✅ 1. DESHABILITA EL TAP AFUERA
              isDismissible: false,
              // ✅ 2. DESHABILITA ARRASTRAR PARA CERRAR
              enableDrag: false,
              builder: (ctx) {
                // --- ¡CAMBIO 6! (Envolvemos el Feedback en el Tema) ---
                return Theme(
                  data: challengeTheme,
                  child: ChallengeFeedbackModal(
                    challengeId: puzzleState.challengeId,
                    isCorrect: esCorrecto,
                    // --- MODIFICADO: Lógica de onContinue ---
                    onContinue: () async {
                      Navigator.of(
                        ctx,
                      ).pop(); // Cierra el pop-up usando el ctx del builder

                      try {
                        // 0. GUARDAR valores actuales ANTES de submitChallengeAttempt
                        final currentStats = ref.read(appBarProvider);
                        ref.read(oldStatsValuesProvider.notifier).state = [
                          currentStats.lives,
                          currentStats.trophies,
                          currentStats.streak,
                        ];

                        // Marcar flag para que Realtime NO actualice mientras estamos en feedback
                        markForStatsRefresh(ref);

                        final repository = ref.read(
                          challengeRepositoryProvider,
                        );
                        // Leemos el estado actual que tiene el ID y los recursos
                        final currentState = ref.read(puzzleProvider);

                        if (esCorrecto) {
                          // 1. Enviar intento y obtener trofeos
                          final int trofeos = await repository
                              .submitChallengeAttempt(
                                retoId: currentState.challengeId,
                                nivelId: currentState.nivelId, // ← ¡AÑADIDO!
                                fueExitoso: true,
                                tiempoQueTardo:
                                    0, // No medimos tiempo en puzzles
                              );

                          // 2. Refrescar Ranking (NO refrescamos stats aquí - se hará al regresar al Home)
                          ref.invalidate(globalRankingProvider);
                          // 3. Refrescar la lista de desafíos mensuales
                          //    Esto hará que la barra de progreso se actualice.
                          ref.invalidate(desafiosProvider);
                          // 3. Navegar a la vista de éxito
                          if (!context.mounted) return;
                          context.push('/challenge_success', extra: trofeos);
                        } else {
                          // 1. Enviar intento fallido (y obtener 0 trofeos)
                          await repository.submitChallengeAttempt(
                            retoId: currentState.challengeId,
                            nivelId: currentState.nivelId, // ← ¡AÑADIDO!
                            fueExitoso: false,
                            tiempoQueTardo: 0,
                          );

                          // 2. Obtener recursos del estado (NO refrescamos stats aquí - se hará al regresar al Home)
                          final List<RecursoModel> recursos =
                              currentState.recursos;

                          // 3. Navegar a la vista de fracaso
                          if (!context.mounted) return;
                          context.push('/challenge_failure', extra: recursos);
                        }
                      } catch (e) {
                        // Mostrar error al usuario
                        if (context.mounted) {
                          // --- MODIFICACIÓN: Se usa el snackbar personalizado ---
                          showErrorSnackbar(
                            context,
                            'Error',
                            'Error al enviar resultado: $e',
                          );
                          // --- FIN MODIFICACIÓN ---
                        }
                      }
                    },
                    // --- FIN MODIFICACIÓN ---
                  ),
                );
                // --- FIN CAMBIO 6 ---
              },
            );
          },
        ),
      ),
    );
    // --- FIN CAMBIO 5 ---
  }
}
