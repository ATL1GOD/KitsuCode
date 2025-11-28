// lib/features/puzzle_game/view/puzzle_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_code_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_instruction_card.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_options_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class PuzzleView extends ConsumerWidget {
  final Function(bool isCorrect)? onOnboardingFinished;
  const PuzzleView({super.key, this.onOnboardingFinished});

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
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarProvider);

    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );

    final colorScheme = challengeTheme.colorScheme;

    final puzzleState = ref.watch(puzzleProvider);
    final puzzleNotifier = ref.read(puzzleProvider.notifier);

    // 🔥 FIX CRÍTICO: Agregamos "|| puzzleState.challenge == null"
    // Esto evita que la app intente pintar la pantalla antes de recibir los datos del JSON.
    if (puzzleState.isLoading || puzzleState.challenge == null) {
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

    // AHORA ES SEGURO USAR EL OPERADOR !
    final challenge = puzzleState.challenge!;
    final bool isPuzzleComplete = !puzzleState.filledBlanks.containsValue(null);

    final int totalBlanks = puzzleState.filledBlanks.length;
    final int filledCount = puzzleState.filledBlanks.values
        .where((v) => v != null)
        .length;

    final double progress = (totalBlanks > 0)
        ? (filledCount / totalBlanks)
        : 0.0;

    return Theme(
      data: challengeTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: ChallengeAppBar2(
          progress: progress,
          // Ocultar botón de cierre si es Onboarding
          onClose: onOnboardingFinished != null
              ? null
              : () {
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

        bottomNavigationBar: PuzzleBottomBar(
          isButtonEnabled: isPuzzleComplete,
          onCheckPressed: () {
            puzzleNotifier.checkSolution();
            final esCorrecto =
                ref.read(puzzleProvider).status == PuzzleStatus.correct;

            // 🔥 LÓGICA ONBOARDING: Retornamos inmediatamente
            if (onOnboardingFinished != null) {
              onOnboardingFinished!(esCorrecto);
              return;
            }

            // --- FLUJO NORMAL ---
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              builder: (ctx) {
                return Theme(
                  data: challengeTheme,
                  child: ChallengeFeedbackModal(
                    challengeId: puzzleState.challengeId,
                    isCorrect: esCorrecto,
                    onContinue: () async {
                      Navigator.of(ctx).pop();

                      try {
                        final currentStats = ref.read(appBarProvider);
                        ref.read(oldStatsValuesProvider.notifier).state = [
                          currentStats.lives,
                          currentStats.trophies,
                          currentStats.streak,
                        ];

                        markForStatsRefresh(ref);

                        final repository = ref.read(
                          challengeRepositoryProvider,
                        );
                        final currentState = ref.read(puzzleProvider);

                        if (esCorrecto) {
                          final int trofeos = await repository
                              .submitChallengeAttempt(
                                retoId: currentState.challengeId,
                                nivelId: currentState.nivelId,
                                fueExitoso: true,
                                tiempoQueTardo: 0,
                              );

                          ref.invalidate(globalRankingProvider);
                          ref.invalidate(desafiosProvider);
                          
                          if (!context.mounted) return;
                          context.push('/challenge_success', extra: trofeos);
                        } else {
                          await repository.submitChallengeAttempt(
                            retoId: currentState.challengeId,
                            nivelId: currentState.nivelId,
                            fueExitoso: false,
                            tiempoQueTardo: 0,
                          );

                          final List<RecursoModel> recursos =
                              currentState.recursos;

                          if (!context.mounted) return;
                          context.push('/challenge_failure', extra: recursos);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(
                            context,
                            'Error',
                            'Error al enviar resultado: $e',
                          );
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}