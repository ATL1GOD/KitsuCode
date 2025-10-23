import 'package:flutter/material.dart';

class QuizResultPage extends StatefulWidget {
  final int marks;
  const QuizResultPage({Key? key, required this.marks}) : super(key: key);
  @override
  _QuizResultPageState createState() => _QuizResultPageState(marks);
}

class _QuizResultPageState extends State<QuizResultPage> {
  final List<String> images = [
    "images/success.png", // Asegúrate de tener estas imágenes en tu proyecto
    "images/good.png",
    "images/bad.png",
  ];

  late String message;
  late String image;

  final int marks;
  _QuizResultPageState(this.marks);

  @override
  void initState() {
    if (marks < 10) {
      // Ajustado a 3 preguntas (5 pts c/u)
      image = images[2];
      message = "Debes esforzarte más...\n" + "Puntaje: $marks";
    } else if (marks < 15) {
      image = images[1];
      message = "Puedes hacerlo mejor...\n" + "Puntaje: $marks";
    } else {
      image = images[0];
      message = "¡Lo hiciste muy bien!\n" + "Puntaje: $marks";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado"),
        automaticallyImplyLeading: false, // No mostrar flecha de regreso
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: Material(
              elevation: 10.0,
              child: Container(
                child: Column(
                  children: <Widget>[
                    Material(
                      child: Container(
                        width: 300.0,
                        height: 300.0,
                        child: ClipRect(child: Image(image: AssetImage(image))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 15.0,
                      ),
                      child: Center(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontFamily: "Quando",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    // Cierra la pantalla de resultados Y la del quiz,
                    // volviendo al mapa.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    "Continuar",
                    style: TextStyle(fontSize: 18.0),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 25.0,
                    ),
                    side: const BorderSide(width: 3.0, color: Colors.indigo),
                    splashFactory:
                        InkRipple.splashFactory, // Reemplaza splashColor
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
