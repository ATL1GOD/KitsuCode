// lib/features/quiz_game/view/widgets/quiz_view.dart

// REMOVIDO: import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart'; // Importa QuizData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';

// --- MODIFICACIÓN: Importación de tu snackbar personalizado ---
import 'package:kitsucode/shared/snackbar/snackbar.dart';
// --- FIN MODIFICACIÓN ---

import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';

// --- FUSIÓN: Se añade el import de TU lógica de animación (dxniel7) ---
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';

class QuizPage extends ConsumerStatefulWidget {
  final QuizData mydata;
  final String retoId;
  final String nivelId; // ← ¡AÑADIDO!

  const QuizPage({
    super.key,
    required this.mydata,
    required this.retoId,
    required this.nivelId, // ← ¡AÑADIDO!
  });

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int marks = 0;
  int i = 0;
  bool disableAnswer = false;
  int j = 1;
  // REMOVIDO: int timer = 30;
  // REMOVIDO: String _showTimer = "30";
  late List<int> _randomArray;
  int totalQuestions = 0;
  String? selectedAnswer;
  // REMOVIDO: bool _cancelTimer = false;
  bool _hasSubmitted = false;
  bool? _wasCorrect;
  bool correct = false;

  @override
  void initState() {
    super.initState();
    // REMOVIDO: _startTimer();
    _genRandomArray();
    if (_randomArray.isNotEmpty) {
      i = _randomArray[0];
    }
  }

  // REMOVIDO: El método dispose() completo, ya que solo gestionaba el _cancelTimer.

  // ... (Las funciones _genRandomArray, _startTimer, _nextQuestion,
  // y _checkAnswer son idénticas o mejores en la versión de 'ELLOS',
  // así que las mantenemos) ...

  void _genRandomArray() {
    if (widget.mydata.questions.isNotEmpty) {
      totalQuestions = widget.mydata.totalQuestions;
      var rand = Random();
      var distinctIds = List<int>.generate(totalQuestions, (index) => index);
      distinctIds.shuffle(rand);
      _randomArray = distinctIds;
      if (kDebugMode) {
        print(_randomArray);
      }
    } else {
      totalQuestions = 0;
      _randomArray = [];
    }
  }

  // REMOVIDO: El método _startTimer() completo.

  void _nextQuestion() {
    // REMOVIDO: _cancelTimer = false;
    // REMOVIDO: timer = 30;
    if (mounted) {
      setState(() {
        if (j < totalQuestions) {
          i = _randomArray[j];
          j++;
        } else {
          if (context.mounted) {
            // NOTA: El cálculo de la duración dependía del temporizador.
            // Se establece en 0.
            // Si necesitas el tiempo total, implementa un Stopwatch
            // en initState() y detenlo aquí.
            const int duration = 0;
            // REMOVIDO: int duration = (30 * totalQuestions) - (timer < 0 ? 0 : timer);

            final double scoreRatio = marks / (totalQuestions * 5);
            final int percentage = (scoreRatio * 100).round();

            _showFeedbackModal(
              percentage: percentage,
              durationInSeconds: duration,
              recursos: widget.mydata.recursos,
            );
          }
          return;
        }
        selectedAnswer = null;
        disableAnswer = false;
        _wasCorrect = null;
      });
    }
    // REMOVIDO: _startTimer();
  }

  void _checkAnswer(String k) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);

    correct = false; // Reset a false

    if (k.isNotEmpty && widget.mydata.answers[questionKey] == k) {
      marks = marks + 5;
      correct = true;
    }

    if (mounted) {
      setState(() {
        // REMOVIDO: _cancelTimer = true;
        disableAnswer = true;
        _wasCorrect = correct;
      });
    }
  }

  // --- Lógica del modal (base de 'ELLOS') ---
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

  // --- FUSIÓN: Se usa TU '_showFeedbackModal' (dxniel7) ---
  // ¡¡Esta es la lógica CORRECTA para trofeos y animación!!
  void _showFeedbackModal({
    required int percentage,
    required int durationInSeconds,
    required List<RecursoModel> recursos,
  }) {
    if (_hasSubmitted) return;

    final bool esCorrecto = (percentage > 50);

    final appBarState = ref.read(appBarProvider);
    // Usar el brightness del Theme actual del contexto
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Theme(
          data: challengeTheme,
          child: ChallengeFeedbackModal(
            challengeId: int.parse(widget.retoId),
            isCorrect: esCorrecto,
            // --- ¡¡TU LÓGICA DE 'onContinue'!! ---
            onContinue: () async {
              Navigator.of(ctx).pop();

              if (_hasSubmitted) return;
              _hasSubmitted = true;

              try {
                // 0. GUARDAR valores actuales (¡TU LÓGICA DE ANIMACIÓN!)
                final currentStats = ref.read(appBarProvider);
                ref.read(oldStatsValuesProvider.notifier).state = [
                  currentStats.lives,
                  currentStats.trophies,
                  currentStats.streak,
                ];

                // Marcar flag (¡TU LÓGICA DE ANIMACIÓN!)
                markForStatsRefresh(ref);

                final repository = ref.read(challengeRepositoryProvider);
                final int retoIdAsInt = int.parse(widget.retoId);
                final int nivelIdAsInt = int.parse(
                  widget.nivelId,
                ); // ← ¡AÑADIDO!

                if (esCorrecto) {
                  // 1. Enviar intento y OBTENER trofeos (¡TU LÓGICA DE TROFEOS!)
                  final int trofeos = await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt, // ← ¡AÑADIDO!
                    fueExitoso: true,
                    tiempoQueTardo: durationInSeconds,
                  );

                  ref.invalidate(globalRankingProvider);

                  // 2. Navegar CON TROFEOS
                  if (!context.mounted) return;
                  // Cambiado a push para mantener la pantalla del quiz en la pila
                  context.push('/challenge_success', extra: trofeos);
                } else {
                  await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt, // ← ¡AÑADIDO!
                    fueExitoso: false,
                    tiempoQueTardo: durationInSeconds,
                  );

                  // 2. Obtener recursos
                  final List<RecursoModel> recursos = widget.mydata.recursos;

                  // 3. Navegar
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
            // --- FIN DE TU LÓGICA ---
          ),
        );
      },
    );
  }
  // --- FIN FUSIÓN ---

  // --- FUSIÓN: Se usa el '_choiceButton' de ELLOS (UI actualizada) ---
  Widget _choiceButton(String k, ColorScheme colorScheme) {
    bool isSelected = selectedAnswer == k;

    Color buttonColor = colorScheme.surfaceContainer;
    Color borderColor = colorScheme.outline;
    Color textColor = colorScheme.onSurface;

    if (disableAnswer) {
      if (isSelected && _wasCorrect == true) {
        // El usuario seleccionó esta y ERA CORRECTA
        buttonColor = Colors.green.withAlpha(51);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isSelected && _wasCorrect == false) {
        // El usuario seleccionó esta y ERA INCORRECTA
        buttonColor = Colors.red.withAlpha(51);
        borderColor = Colors.red;
        textColor = Colors.red;
      }
    } else if (isSelected) {
      buttonColor = colorScheme.primaryContainer.withAlpha(77);
      borderColor = colorScheme.primary;
      textColor = colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: buttonColor,
          side: BorderSide(color: borderColor),
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onPressed: disableAnswer
            ? null
            : () {
                setState(() {
                  selectedAnswer = k;
                });
              },
        child: Text(
          widget.mydata.options[widget.mydata.questions.keys.elementAt(
                i,
              )]![k] ??
              "",
          textAlign: TextAlign.start,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: "Alike",
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  // --- FUSIÓN: Se usa la UI de ELLOS (refactorizada) ---
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    // Obtener el brightness del sistema actual
    final brightness = Theme.of(context).brightness;
    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      brightness,
    );
    final colorScheme = challengeTheme.colorScheme;

    if (_randomArray.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String questionKey = widget.mydata.questions.keys.elementAt(i);
    double progress = j / totalQuestions;

    return Theme(
      data: challengeTheme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic _) {
          if (didPop) return;
          showExitDialog(context);
        },
        child: Scaffold(
          appBar: ChallengeAppBar2(
            progress: progress,
            onClose: () {
              showExitDialog(context);
            },
          ),
          body: _buildQuizBody(colorScheme, questionKey),
          bottomNavigationBar: _buildBottomBar(colorScheme),
        ),
      ),
    );
  }

  /// Widget que construye el cuerpo principal del quiz (pregunta y opciones).
  Widget _buildQuizBody(ColorScheme colorScheme, String questionKey) {
    // 🎯 OPTIMIZACIÓN: Memoizar MediaQuery para evitar llamadas múltiples
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                screenHeight - AppBar().preferredSize.height - topPadding - 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              Text(
                "Selecciona la respuesta correcta",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildQuestionCard(
                widget.mydata.questions[questionKey] ?? "Cargando...",
                colorScheme,
              ),
              const SizedBox(height: 30),
              // Opciones de respuesta
              AbsorbPointer(
                absorbing: disableAnswer,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _choiceButton('a', colorScheme),
                    _choiceButton('b', colorScheme),
                    _choiceButton('c', colorScheme),
                    _choiceButton('d', colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Espacio para el BottomBar
            ],
          ),
        ),
      ),
    );
  }

  /// Widget que construye la tarjeta de la pregunta.
  Widget _buildQuestionCard(String text, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22.0,
          fontFamily: "Quando",
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Widget que construye la barra de navegación inferior (botón de Comprobar/Continuar).
  Widget _buildBottomBar(ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: disableAnswer
                  ? (_wasCorrect == true ? Colors.green : Colors.red)
                  : (selectedAnswer != null
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: (selectedAnswer == null && !disableAnswer)
                ? null
                : () {
                    if (disableAnswer) {
                      _nextQuestion();
                    } else {
                      _checkAnswer(selectedAnswer!);
                    }
                  },
            child: Text(
              disableAnswer ? "CONTINUAR" : "COMPROBAR",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
