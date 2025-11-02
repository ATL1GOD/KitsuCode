import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/result_page.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
// import 'package:kitsucode/features/quiz_game/provider/quiz_provider.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';

class QuizPage extends StatefulWidget {
  final QuizData mydata;

  const QuizPage({super.key, required this.mydata});
  @override
  _QuizPageState createState() => _QuizPageState();
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
          // Llama a _checkAnswer con una cadena vacía para indicar tiempo agotado
          // y pasamos el ColorScheme temporalmente
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
            // Se calcula el tiempo total usado al finalizar
            int duration = (30 * totalQuestions) - timer;
            if (duration < 0) duration = 0; // Evita valores negativos

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => QuizResultPage(
                  marks: marks,
                  totalQuestions: totalQuestions,
                  durationInSeconds: duration,
                ),
              ),
            );
          }
          return;
        }
        selectedAnswer = null;
        disableAnswer = false;
      });
    }
    _startTimer();
  }

  // Se corrige la firma para recibir ColorScheme
  void _checkAnswer(String k, ColorScheme pythonColorScheme) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);
    // Solo aumentamos puntos si se selecciona una respuesta (k.isNotEmpty) y es correcta
    if (k.isNotEmpty &&
        widget.mydata.answers[questionKey] ==
            widget.mydata.options[questionKey]![k]) {
      marks = marks + 5;
    }

    if (mounted) {
      setState(() {
        _cancelTimer = true;
        disableAnswer = true;
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
      String correctAnswerKey = '';
      widget.mydata.options[questionKey]!.forEach((key, value) {
        if (value == widget.mydata.answers[questionKey]) {
          correctAnswerKey = key;
        }
      });

      if (k == correctAnswerKey) {
        buttonColor = Colors.green.withAlpha(51);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isSelected && k != correctAnswerKey) {
        buttonColor = Colors.red.withAlpha(51);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        borderColor = Colors.grey.shade400.withAlpha(128);
        textColor = Colors.grey.shade400;
      }
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
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: borderColor, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        onPressed: disableAnswer
            ? null // Deshabilitar si ya se comprobó
            : () {
                setState(() {
                  selectedAnswer = k;
                });
              },
        child: Text(
          widget.mydata.options[questionKey]![k] ?? "",
          style: const TextStyle(
            fontFamily: "Alike",
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("¿Salir del reto?"),
                    content: const Text("Tu progreso se perderá."),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
              },
            ),
            title: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _showTimer,
                  style: TextStyle(
                    color: pythonColorScheme.onSurface,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
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
                      100, // Ajusta este valor si es necesario
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Se cambia a start
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
                    _buildDuolingoQuestionArea(
                      widget.mydata.questions[questionKey] ?? "Cargando...",
                      pythonColorScheme,
                    ),
                    const SizedBox(
                      height: 30,
                    ), // Espacio después de la pregunta
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
                    // Espacio para empujar el contenido hacia arriba y dejar espacio al botón fijo
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          // Botón inferior fijo
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
                        ? (marks > (j - 1) * 5 ? Colors.green : Colors.red)
                        : (selectedAnswer != null
                              ? pythonColorScheme
                                    .primary // Si hay respuesta, primario
                              : Colors
                                    .green), // Color por defecto si no está deshabilitado
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  onPressed: (selectedAnswer == null && !disableAnswer)
                      ? null
                      : () {
                          if (disableAnswer) {
                            _nextQuestion();
                          } else {
                            // Se llama _checkAnswer con el ColorScheme correcto
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
    );
  }
}

Widget _buildDuolingoQuestionArea(
  String questionText,
  ColorScheme colorScheme,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Image.asset(
        'assets/images/fox_character.png',
        width: 100,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.error),
          );
        },
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline, width: 2),
            borderRadius: BorderRadius.circular(15),
            color: colorScheme.surfaceContainer,
          ),
          child: Text(
            questionText,
            style: TextStyle(
              fontSize: 20.0,
              fontFamily: "Quando",
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ],
  );
}
