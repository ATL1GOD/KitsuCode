import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/result_page.dart'; // Ajusta la ruta

class QuizPage extends StatefulWidget {
  final List mydata;

  const QuizPage({Key? key, required this.mydata}) : super(key: key);
  @override
  _QuizPageState createState() => _QuizPageState(mydata);
}

class _QuizPageState extends State<QuizPage> {
  final List mydata;
  _QuizPageState(this.mydata);

  Color colortoshow = Colors.indigoAccent;
  Color right = Colors.green;
  Color wrong = Colors.red;
  int marks = 0;
  int i = 0; // Índice de la pregunta actual
  bool disableAnswer = false;
  int j = 1; // Contador de preguntas respondidas
  int timer = 30;
  String showtimer = "30";
  late List<int> random_array; // Usaremos los índices de las claves
  int totalQuestions = 0;

  Map<String, Color> btncolor = {
    "a": Colors.indigoAccent,
    "b": Colors.indigoAccent,
    "c": Colors.indigoAccent,
    "d": Colors.indigoAccent,
  };

  bool canceltimer = false;

  @override
  void initState() {
    starttimer();
    genrandomarray();
    // Establece la primera pregunta
    i = random_array[0];
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void genrandomarray() {
    // mydata[0] es el mapa de preguntas
    totalQuestions = mydata[0].length;
    var rand = Random();

    // Creamos una lista de índices de 0 a totalQuestions-1
    var distinctIds = List<int>.generate(totalQuestions, (index) => index);

    // Mezclamos la lista
    distinctIds.shuffle(rand);

    // Usamos la lista mezclada
    random_array = distinctIds;
    print(random_array);
  }

  void starttimer() async {
    const onesec = Duration(seconds: 1);
    Timer.periodic(onesec, (Timer t) {
      setState(() {
        if (timer < 1) {
          t.cancel();
          nextquestion();
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
    setState(() {
      if (j < totalQuestions) {
        i = random_array[j];
        j++;
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => QuizResultPage(marks: marks)),
        );
      }
      btncolor["a"] = Colors.indigoAccent;
      btncolor["b"] = Colors.indigoAccent;
      btncolor["c"] = Colors.indigoAccent;
      btncolor["d"] = Colors.indigoAccent;
      disableAnswer = false;
    });
    starttimer();
  }

  void checkanswer(String k) {
    // Obtenemos la clave de la pregunta actual (p.ej., "1", "2")
    // mydata[0] es el Map de preguntas. Sus claves son lo que necesitamos.
    String questionKey = mydata[0].keys.elementAt(i);

    // mydata[2] es el Map de respuestas.
    // mydata[1] es el Map de opciones.
    if (mydata[2][questionKey] == mydata[1][questionKey][k]) {
      marks = marks + 5;
      colortoshow = right;
    } else {
      colortoshow = wrong;
    }
    setState(() {
      btncolor[k] = colortoshow;
      canceltimer = true;
      disableAnswer = true;
    });
    Timer(const Duration(seconds: 2), nextquestion);
  }

  Widget choicebutton(String k) {
    // Obtenemos la clave de la pregunta actual (p.ej., "1", "2")
    String questionKey = mydata[0].keys.elementAt(i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: MaterialButton(
        onPressed: () => checkanswer(k),
        child: Text(
          mydata[1][questionKey][k] ?? "", // Opción de la pregunta
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "Alike",
            fontSize: 16.0,
          ),
          maxLines: 1,
        ),
        color: btncolor[k],
        splashColor: Colors.indigo[700],
        highlightColor: Colors.indigo[700],
        minWidth: 200.0,
        height: 45.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
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

    // Obtenemos la clave de la pregunta actual
    String questionKey = (mydata.isNotEmpty && mydata[0].keys.isNotEmpty)
        ? mydata[0].keys.elementAt(i)
        : "";

    return WillPopScope(
      onWillPop: () {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Kitsucode"),
            content: const Text("No puedes retroceder en medio de un reto."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        ).then((value) => false); // Devuelve false para no cerrar la ruta
      },
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(15.0),
                alignment: Alignment.bottomLeft,
                child: Text(
                  mydata[0][questionKey] ??
                      "Cargando...", // Texto de la pregunta
                  style: const TextStyle(fontSize: 16.0, fontFamily: "Quando"),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: AbsorbPointer(
                absorbing: disableAnswer,
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      choicebutton('a'),
                      choicebutton('b'),
                      choicebutton('c'),
                      choicebutton('d'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.topCenter,
                child: Center(
                  child: Text(
                    showtimer,
                    style: const TextStyle(
                      fontSize: 35.0,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
