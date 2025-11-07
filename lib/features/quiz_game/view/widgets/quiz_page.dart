// lib/features/quiz_game/view/widgets/quiz_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/result_page.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';

class QuizPage extends StatefulWidget {
  final QuizData mydata;
  final String retoId;

  const QuizPage({super.key, required this.mydata, required this.retoId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
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
  bool? _wasCorrect;

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

  void _startTimer() async {
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
          final pythonColorScheme = (brightness == Brightness.dark)
              ? pythonDarkColorScheme
              : pythonLightColorScheme;
          _checkAnswer("", pythonColorScheme);
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

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => QuizResultPage(
                  marks: marks,
                  totalQuestions: totalQuestions,
                  durationInSeconds: duration,
                  retoId: widget.retoId,
                ),
              ),
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

  void _checkAnswer(String k, ColorScheme pythonColorScheme) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);
    bool correct = false;

    if (k.isNotEmpty && k == widget.mydata.answers[questionKey]) {
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

  Widget _choiceButton(String k, ColorScheme pythonColorScheme) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);
    bool isSelected = selectedAnswer == k;

    Color buttonColor = pythonColorScheme.surfaceContainer;
    Color borderColor = pythonColorScheme.outline;
    Color textColor = pythonColorScheme.onSurface;

    if (disableAnswer) {
      final String correctOptionKey = widget.mydata.answers[questionKey] ?? '';

      // --- ¡CAMBIO 2! Lógica para ocultar la respuesta correcta si falló ---
      // 1. Mostrar VERDE: Solo si la opción actual (k) es la correcta Y el usuario la seleccionó (o si el tiempo acabó y no seleccionó nada).
      if (k == correctOptionKey && (isSelected || selectedAnswer == null)) {
        buttonColor = Colors.green.withAlpha(51);
        borderColor = Colors.green;
        textColor = Colors.green;
      }
      // 2. Mostrar ROJO: Si el usuario la seleccionó (isSelected) y NO es la correcta.
      else if (isSelected && k != correctOptionKey) {
        buttonColor = Colors.red.withAlpha(51);
        borderColor = Colors.red;
        textColor = Colors.red;
      }
      // 3. Demás opciones (incluyendo la respuesta correcta si el usuario falló, y las incorrectas no seleccionadas)
      else {
        borderColor = pythonColorScheme.outline;
        textColor = pythonColorScheme.onSurface;
        buttonColor = pythonColorScheme.surfaceContainer;
      }
      // --- FIN CAMBIO 2 ---
    } else if (isSelected) {
      buttonColor = pythonColorScheme.primaryContainer.withAlpha(77);
      borderColor = pythonColorScheme.primary;
      textColor = pythonColorScheme.primary;
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
          widget.mydata.options[questionKey]![k] ?? "",
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    final brightness = MediaQuery.of(context).platformBrightness;
    final pythonColorScheme = (brightness == Brightness.dark)
        ? pythonDarkColorScheme
        : pythonLightColorScheme;

    if (_randomArray.isEmpty) {
      return Scaffold(
        backgroundColor: pythonColorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String questionKey = widget.mydata.questions.keys.elementAt(i);
    double progress = j / totalQuestions;

    return Theme(
      data: ThemeData.from(
        colorScheme: pythonColorScheme,
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: pythonColorScheme.surface),
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
            backgroundColor: pythonColorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: pythonColorScheme.onSurface),
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
                          Navigator.of(context).pop();
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
                      backgroundColor: pythonColorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pythonColorScheme.primary,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pythonColorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _showTimer,
                    style: TextStyle(
                      color: pythonColorScheme.onPrimaryContainer,
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
                        color: pythonColorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildQuestionCard(
                      widget.mydata.questions[questionKey] ?? "Cargando...",
                      pythonColorScheme,
                    ),
                    const SizedBox(height: 30),
                    // Opciones de respuesta
                    AbsorbPointer(
                      absorbing: disableAnswer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _choiceButton('a', pythonColorScheme),
                          _choiceButton('b', pythonColorScheme),
                          _choiceButton('c', pythonColorScheme),
                          _choiceButton('d', pythonColorScheme),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: disableAnswer
                        ? (_wasCorrect == true
                              ? Colors.green.shade600
                              : pythonColorScheme.error)
                        : (selectedAnswer != null
                              ? pythonColorScheme.primary
                              : pythonColorScheme.surfaceContainerHighest),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    onPressed: (selectedAnswer == null && !disableAnswer)
                        ? null
                        : () {
                            if (disableAnswer) {
                              _nextQuestion();
                            } else {
                              _checkAnswer(selectedAnswer!, pythonColorScheme);
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
            color: colorScheme.shadow.withOpacity(0.1),
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
