import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/result_page.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/features/quiz_game/provider/quiz_provider.dart';

class QuizPage extends StatefulWidget {
  final QuizData mydata;

  const QuizPage({super.key, required this.mydata});
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Color right = Colors.green;
  final Color wrong = Colors.red;

  int marks = 0;
  int i = 0; // Índice de la pregunta actual
  bool disableAnswer = false;
  int j = 1; // Contador de preguntas respondidas
  int timer = 30;
  String showtimer = "30";
  late List<int> random_array;
  int totalQuestions = 0;

  String? selectedAnswer;

  Map<String, Color> btncolor = {
    "a": Colors.transparent,
    "b": Colors.transparent,
    "c": Colors.transparent,
    "d": Colors.transparent,
  };

  bool canceltimer = false;

  @override
  void initState() {
    super.initState();
    starttimer();
    genrandomarray();
    if (random_array.isNotEmpty) {
      i = random_array[0];
    }
  }

  @override
  void dispose() {
    canceltimer = true;
    super.dispose();
  }

  void genrandomarray() {
    if (widget.mydata.questions.isNotEmpty) {
      totalQuestions = widget.mydata.totalQuestions;
      var rand = Random();
      var distinctIds = List<int>.generate(totalQuestions, (index) => index);
      distinctIds.shuffle(rand);
      random_array = distinctIds;
      if (kDebugMode) {
        print(random_array);
      }
    } else {
      totalQuestions = 0;
      random_array = [];
    }
  }

  void starttimer() async {
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
          checkanswer("", pythonLightColorScheme);
        } else if (canceltimer == true) {
          t.cancel();
        } else {
          timer = timer - 1;
        }
        showtimer = timer.toString();
      });
    });
  }

  void nextquestion() {
    canceltimer = false;
    timer = 30;
    if (mounted) {
      setState(() {
        if (j < totalQuestions) {
          i = random_array[j];
          j++;
        } else {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => QuizResultPage(marks: marks),
              ),
            );
          }
          return;
        }
        selectedAnswer = null;
        disableAnswer = false;
        btncolor = {
          "a": Colors.transparent,
          "b": Colors.transparent,
          "c": Colors.transparent,
          "d": Colors.transparent,
        };
      });
    }
    starttimer();
  }

  // k es la respuesta seleccionada ('a', 'b', 'c', 'd')
  void checkanswer(String k, ColorScheme pythonColorScheme) {
    String questionKey = widget.mydata.questions.keys.elementAt(i);
    if (k.isNotEmpty &&
        widget.mydata.answers[questionKey] ==
            widget.mydata.options[questionKey]![k]) {
      marks = marks + 5;
    }

    if (mounted) {
      setState(() {
        canceltimer = true;
        disableAnswer = true;
      });
    }

    // ✨ CAMBIO: Se eliminó el Timer de 2 segundos para que el avance sea manual.
    // Timer(const Duration(seconds: 2), nextquestion);
  }

  // --- WIDGET DE BOTÓN REDISEÑADO ---
  Widget choicebutton(String k, ColorScheme pythonColorScheme) {
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
        buttonColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isSelected && k != correctAnswerKey) {
        buttonColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        borderColor = Colors.grey.shade400.withOpacity(0.5);
        textColor = Colors.grey.shade400;
      }
    } else if (isSelected) {
      buttonColor = pythonColorScheme.primaryContainer.withOpacity(0.3);
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
        onPressed: () {
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

  // --- WIDGET DE BUILD REDISEÑADO ---
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

    if (random_array.isEmpty) {
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
      child: WillPopScope(
        onWillPop: () {
          return showDialog(
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
          ).then((value) => value ?? false);
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
                  showtimer,
                  style: TextStyle(
                    color: pythonColorScheme.onSurface,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              // ✨ CAMBIO: Lógica del botón actualizada
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: disableAnswer
                      ? (marks > (j - 1) * 5 ? Colors.green : Colors.red)
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                onPressed: (selectedAnswer == null && !disableAnswer)
                    ? null // Deshabilita si no se ha seleccionado respuesta
                    : () {
                        if (disableAnswer) {
                          // Si la respuesta ya fue comprobada, avanza
                          nextquestion();
                        } else {
                          // Si no, comprueba la respuesta
                          checkanswer(selectedAnswer!, pythonColorScheme);
                        }
                      },
                child: Text(
                  disableAnswer ? "CONTINUAR" : "COMPROBAR", // Cambia el texto
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    AbsorbPointer(
                      absorbing: disableAnswer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          choicebutton('a', pythonColorScheme),
                          choicebutton('b', pythonColorScheme),
                          choicebutton('c', pythonColorScheme),
                          choicebutton('d', pythonColorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET PARA MOSTRAR LA PREGUNTA COMO DUOLINGO ---
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
