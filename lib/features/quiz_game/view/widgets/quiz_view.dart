// lib/features/quiz_game/view/widgets/quiz_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart'; // Importa QuizData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:giffy_dialog/giffy_dialog.dart';

class QuizPage extends ConsumerStatefulWidget {
  final QuizData mydata;
  final String retoId;

  const QuizPage({super.key, required this.mydata, required this.retoId});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

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
          // --- REFACTOR: 'colorScheme' ya no es necesario aquí ---
          // Simplemente llama a _checkAnswer.
          _checkAnswer("");
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

  // --- REFACTOR: ¡Parámetro 'colorScheme' eliminado! ---
  // No se estaba usando dentro de la función, así que lo eliminé
  // para simplificar el código y las llamadas a esta función.
  void _checkAnswer(String k) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);

    correct = false; // Reset a false

    if (k.isNotEmpty && widget.mydata.answers[questionKey] == k) {
      marks = marks + 5;
      correct = true;
    }

    if (mounted) {
      setState(() {
        _cancelTimer = true;
        disableAnswer = true;
        _wasCorrect = correct;
      });
    }
  }

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
      // ✅ 1. DESHABILITA EL TAP AFUERA
      isDismissible: false,
      // ✅ 2. DESHABILITA ARRASTRAR PARA CERRAR
      enableDrag: false,
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

  Widget _choiceButton(String k, ColorScheme colorScheme) {
    bool isSelected = selectedAnswer == k;

    Color buttonColor = colorScheme.surfaceContainer;
    Color borderColor = colorScheme.outline;
    Color textColor = colorScheme.onSurface;

    if (disableAnswer) {
      if (isSelected && _wasCorrect == true) {
        buttonColor = Colors.green.withAlpha(51);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isSelected && _wasCorrect == false) {
        buttonColor = Colors.red.withAlpha(51);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        borderColor = colorScheme.outline;
        textColor = colorScheme.onSurface;
        buttonColor = colorScheme.surfaceContainer;
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

  // --- REFACTOR (PASO 1): Extraer Widgets del 'build' ---
  // El método 'build' se vuelve mucho más limpio al
  // mover la construcción de UI compleja a métodos privados.

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    final brightness = MediaQuery.of(context).platformBrightness;
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

    // --- REFACTOR (PASO 2): 'build' método limpio ---
    // Ahora el método 'build' solo se encarga de ensamblar las piezas.
    return Theme(
      data: challengeTheme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic _) {
          if (didPop) return;
          _showExitDialog();
        },
        child: Scaffold(
          appBar: _buildAppBar(colorScheme, progress),
          body: _buildQuizBody(colorScheme, questionKey),
          bottomNavigationBar: _buildBottomBar(colorScheme),
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación para salir del reto.
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GiffyDialog.image(
          Image.asset(
            "images/challenge/alerta1.png",
            // "assets/images/challenge/alerta1.png",
            height: 280,
            fit: BoxFit.cover,
            // fit: BoxFit.contain,
          ),
          title: const Text(
            '¿Quieres salir del reto?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tu progreso en este reto se perderá.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19),
          ),
          actions: [
            // --- BOTÓN CANCELAR (PERSONALIZADO) ---
            TextButton(
              style: TextButton.styleFrom(
                // Cambia el color del texto
                foregroundColor: Colors.grey[700],
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.pop(context), // Cierra el diálogo
              child: const Text('CANCELAR'),
            ),
            const SizedBox(width: 98),
            // --- BOTÓN SALIR (PERSONALIZADO) ---
            TextButton(
              style: TextButton.styleFrom(
                // Añade un color de fondo
                backgroundColor: Colors.red,
                // Cambia el color del texto a blanco
                foregroundColor: Colors.white,
                // Añade bordes redondeados
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                // Cierra el diálogo y LUEGO sale de la QuizPage
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('SALIR'),
            ),
          ],
        );
      },
    );
  }

  /// Widget que construye el AppBar de la página.
  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, double progress) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: colorScheme.onSurface),
        onPressed: _showExitDialog, // Lógica de 'X' reparada
      ),
      title: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
    );
  }

  /// Widget que construye el cuerpo principal del quiz (pregunta y opciones).
  Widget _buildQuizBody(ColorScheme colorScheme, String questionKey) {
    return SingleChildScrollView(
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
                      // --- REFACTOR: Llamada simplificada ---
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
