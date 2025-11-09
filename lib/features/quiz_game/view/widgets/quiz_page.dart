// lib/features/quiz_game/view/widgets/quiz_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:kitsucode/features/quiz_game/view/widgets/result_page.dart'; // <-- ELIMINADO
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart'; // Importa QuizData

// --- ¡NUEVOS IMPORTS! (Copiados de result_page.dart) ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
// --- FIN NUEVOS IMPORTS ---

// --- ¡Convertido a ConsumerStatefulWidget! ---
class QuizPage extends ConsumerStatefulWidget {
  final QuizData mydata;
  final String retoId;

  const QuizPage({super.key, required this.mydata, required this.retoId});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

// --- ¡Convertido a ConsumerState! ---
class _QuizPageState extends ConsumerState<QuizPage> {
  int marks = 0;
  int i = 0;
  bool disableAnswer = false;
  int j = 1;
  int timer = 30;
  String _showTimer = "30";
  late List<int> _randomArray;
  int totalQuestions = 0;
  String? selectedAnswer;
  bool _cancelTimer = false;
  bool _hasSubmitted = false;
  bool? _wasCorrect;
  bool correct = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _genRandomArray();
    if (_randomArray.isNotEmpty) {
      i = _randomArray[0];
    }
  }

  @override
  void dispose() {
    _cancelTimer = true;
    super.dispose();
  }

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

  void _startTimer() {
    const onesec = Duration(seconds: 1);
    Timer.periodic(onesec, (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (disableAnswer) {
          return;
        }

        if (timer < 1) {
          t.cancel();
          final brightness = MediaQuery.of(context).platformBrightness;
          // --- INICIO DE LA CORRECCIÓN ---

          // 1. Obtenemos el estado del AppBar (para saber el lenguaje)
          //    Usamos .watch para que reaccione si cambia
          final appBarState = ref.watch(appBarProvider);

          // 2. Usamos TU PROPIA función helper para obtener el tema correcto
          final challengeTheme = _getLanguageTheme(
            appBarState.languageName,
            brightness,
          );

          // 3. Extraemos el esquema de color
          final colorScheme = challengeTheme.colorScheme;

          // --- FIN DE LA CORRECCIÓN ---
          _checkAnswer("", colorScheme);
        } else if (_cancelTimer == true) {
          t.cancel();
        } else {
          timer = timer - 1;
        }
        _showTimer = timer.toString();
      });
    });
  }

  void _nextQuestion() {
    _cancelTimer = false;
    timer = 30;
    if (mounted) {
      setState(() {
        if (j < totalQuestions) {
          i = _randomArray[j];
          j++;
        } else {
          if (context.mounted) {
            int duration = (30 * totalQuestions) - (timer < 0 ? 0 : timer);

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
    _startTimer();
  }

  // --- ¡¡¡AQUÍ ESTÁ LA CORRECCIÓN DE LÓGICA!!! ---
  void _checkAnswer(String k, ColorScheme colorScheme) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);

    // --- ¡CAMBIO IMPORTANTE! ---
    // Resetea 'correct' a false al inicio de cada comprobación.
    // Esto asegura que _wasCorrect se actualice correctamente a 'false' si la respuesta es incorrectA.
    correct = false;

    // Compara la 'letra' seleccionada (k) con la 'letra' de la respuesta (answers[questionKey])
    if (k.isNotEmpty && widget.mydata.answers[questionKey] == k) {
      marks = marks + 5;
      correct = true; // <-- Solo se pone 'true' si acierta
    }

    if (mounted) {
      setState(() {
        _cancelTimer = true;
        disableAnswer = true;
        _wasCorrect = correct; // <-- Ahora 'correct' será 'false' si falló
      });
    }
  }
  // --- FIN DE LA CORRECCIÓN ---

  // --- Lógica del modal (movida de result_page) ---
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

  void _showFeedbackModal({
    required int percentage,
    required int durationInSeconds,
    required List<RecursoModel> recursos,
  }) {
    if (_hasSubmitted) return;

    final bool esCorrecto = (percentage > 50);

    final appBarState = ref.read(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) {
        return Theme(
          data: challengeTheme,
          child: ChallengeFeedbackModal(
            isCorrect: esCorrecto,
            onContinue: () async {
              Navigator.of(ctx).pop();

              if (_hasSubmitted) return;
              _hasSubmitted = true;

              final repository = ref.read(challengeRepositoryProvider);
              final int retoIdAsInt = int.parse(widget.retoId);

              if (esCorrecto) {
                await repository.submitChallengeAttempt(
                  retoId: retoIdAsInt,
                  fueExitoso: true,
                  tiempoQueTardo: durationInSeconds,
                );

                ref.read(appBarProvider.notifier).fetchStats();
                ref.invalidate(globalRankingProvider);

                if (!context.mounted) return;
                context.pushReplacement('/challenge_success', extra: 0);
              } else {
                await repository.submitChallengeAttempt(
                  retoId: retoIdAsInt,
                  fueExitoso: false,
                  tiempoQueTardo: durationInSeconds,
                );

                ref.read(appBarProvider.notifier).fetchStats();

                if (!context.mounted) return;
                context.pushReplacement('/challenge_failure', extra: recursos);
              }
            },
          ),
        );
      },
    );
  }

  // --- ¡WIDGET _choiceButton CORREGIDO! ---
  Widget _choiceButton(String k, ColorScheme colorScheme) {
    bool isSelected = selectedAnswer == k;

    Color buttonColor = colorScheme.surfaceContainer;
    Color borderColor = colorScheme.outline;
    Color textColor = colorScheme.onSurface;

    if (disableAnswer) {
      // --- ¡LÓGICA COMPLETAMENTE MODIFICADA PARA TU REQUISITO! ---

      // _wasCorrect fue establecido por _checkAnswer
      // _wasCorrect es 'true' si acertó, 'false' si falló o se acabó el tiempo.

      // Caso 1: El usuario seleccionó ESTE botón (isSelected) Y fue la respuesta CORRECTA
      if (isSelected && _wasCorrect == true) {
        buttonColor = Colors.green.withAlpha(51);
        borderColor = Colors.green;
        textColor = Colors.green;
      }
      // Caso 2: El usuario seleccionó ESTE botón (isSelected) Y fue la respuesta INCORRECTA
      // (o si se acabó el tiempo y este estaba seleccionado)
      else if (isSelected && _wasCorrect == false) {
        buttonColor = Colors.red.withAlpha(51);
        borderColor = Colors.red;
        textColor = Colors.red;
      }
      // Caso 3: Todos los demás botones (no seleccionados, o si se acabó el tiempo y no se seleccionó nada).
      // Estos permanecen en su estado neutral.
      // ¡Esto evita que la respuesta correcta se muestre en verde si el usuario falló!
      else {
        borderColor = colorScheme.outline;
        textColor = colorScheme.onSurface;
        buttonColor = colorScheme.surfaceContainer;
      }
      // --- FIN DE LA MODIFICACIÓN ---
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
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ), // Ajuste de padding horizontal
          side: BorderSide(color: borderColor, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
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
          // --- ¡CAMBIO 1! Permitir autoajuste y saltos de línea ---
          textAlign: TextAlign.start,
          maxLines: 5, // Permitir más líneas si es necesario
          overflow:
              TextOverflow.ellipsis, // Mostrar puntos suspensivos si no cabe
          style: const TextStyle(
            fontFamily: "Alike",
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            height: 1.3, // Mejorar el espaciado entre líneas para legibilidad
          ),
          // --- FIN CAMBIO 1 ---
        ),
      ),
    );
  }
  // --- FIN DE LA CORRECCIÓN DE _choiceButton ---

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    final brightness = MediaQuery.of(context).platformBrightness;
    // --- INICIO DE LA CORRECCIÓN ---

    // 1. Obtenemos el estado del AppBar (para saber el lenguaje)
    //    Usamos .watch para que reaccione si cambia
    final appBarState = ref.watch(appBarProvider);

    // 2. Usamos TU PROPIA función helper para obtener el tema correcto
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      brightness,
    );

    // 3. Extraemos el esquema de color
    final colorScheme = challengeTheme.colorScheme;

    // --- FIN DE LA CORRECCIÓN ---

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

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Kitsucode"),
              content: const Text("No puedes retroceder en medio de un reto."),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              // --- ¡CAMBIO 3! Lógica reparada para el botón 'X' ---
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("¿Salir del reto?"),
                    content: const Text("Tu progreso se perderá."),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cierra el AlertDialog
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Cierra el AlertDialog y luego sale de la QuizPage
                          Navigator.of(context).pop();
                          context.pop();
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
              },
              // --- FIN CAMBIO 3 ---
            ),
            title: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _showTimer,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      AppBar().preferredSize.height -
                      MediaQuery.of(context).padding.top -
                      100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Text(
                      "Selecciona la traducción correcta",
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
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disableAnswer
                        // AHORA ESTO FUNCIONARÁ
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
                            _checkAnswer(selectedAnswer!, colorScheme);
                          }
                        },
                  child: Text(
                    disableAnswer ? "CONTINUAR" : "COMPROBAR",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
}
