// lib/features/codigo_game/view/codigo_view.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';

class CodigoChallengeView extends StatefulWidget {
  final CodigoChallenge challenge;
  final String retoId;

  const CodigoChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
  });

  @override
  State<CodigoChallengeView> createState() => _CodigoChallengeViewState();
}

class _CodigoChallengeViewState extends State<CodigoChallengeView> {
  late final PageController _pageController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Estado para la retroalimentación
  bool _mostrandoFeedback = false;
  bool _esRespuestaCorrecta = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Asegurarse de que el TextField tenga foco automáticamente
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verificarRespuesta() {
    final int currentIndex = _pageController.page?.round() ?? 0;
    final preguntaActual = widget.challenge.preguntas[currentIndex];

    final respuestaUsuario = _textController.text;
    final respuestaCorrecta = preguntaActual.respuesta_correcta;

    // Comparamos ignorando may/min y espacios al inicio/final
    final esCorrecta =
        respuestaUsuario.trim().toLowerCase() ==
        respuestaCorrecta.trim().toLowerCase();

    setState(() {
      _esRespuestaCorrecta = esCorrecta;
      _mostrandoFeedback = true;
    });

    // Si es correcta, avanzamos después de un momento
    if (esCorrecta) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _siguientePregunta();
      });
    } else {
      // Si es incorrecta, solo ocultamos el feedback después de un momento
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _mostrandoFeedback = false;
        });
      });
    }
  }

  void _siguientePregunta() {
    final int currentIndex = _pageController.page?.round() ?? 0;
    if (currentIndex < widget.challenge.preguntas.length - 1) {
      // Avanza a la siguiente página
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _textController.clear();
      setState(() {
        _mostrandoFeedback = false;
      });
      _focusNode.requestFocus(); // Devuelve el foco al textfield
    } else {
      // TODO: Terminó el reto. Navegar a la pantalla de resultados.
      Navigator.of(context).pop(); // De momento solo salimos
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilo para el código (fondo oscuro, texto claro)
    const codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: Colors.white,
      height: 1.5,
    );
    // Estilo para el input (ligeramente diferente para destacarlo)
    const inputStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: Colors.cyanAccent,
      fontWeight: FontWeight.bold,
      height: 1.5,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Completa el Código')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // No deslizar
              itemCount: widget.challenge.preguntas.length,
              itemBuilder: (context, index) {
                final pregunta = widget.challenge.preguntas[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Instrucción
                      Text(
                        pregunta.instruccion,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),

                      // 2. Bloque de Código (Fondo oscuro)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // Color tipo VS Code
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        // Usamos RichText para combinar texto y el TextField
                        child: RichText(
                          text: TextSpan(
                            style: codeStyle,
                            children: [
                              TextSpan(text: pregunta.texto_antes),
                              // El WidgetSpan nos deja meter un TextField en línea
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: IntrinsicWidth(
                                  // Ajusta el ancho al contenido
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    style: inputStyle,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _verificarRespuesta(),
                                  ),
                                ),
                              ),
                              TextSpan(text: pregunta.texto_despues),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Botón de Verificar y Feedback
          _buildFeedbackContainer(),
        ],
      ),
    );
  }

  // Widget para el footer con el botón y el feedback
  Widget _buildFeedbackContainer() {
    // Si no estamos mostrando feedback, muestra el botón de verificar
    if (!_mostrandoFeedback) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verificarRespuesta,
            child: const Text('Verificar'),
          ),
        ),
      );
    }

    // Si mostramos feedback, muestra el banner de color
    final color = _esRespuestaCorrecta
        ? Colors.green.shade700
        : Colors.red.shade700;
    final texto = _esRespuestaCorrecta ? "¡Correcto!" : "Inténtalo de nuevo";
    final icono = _esRespuestaCorrecta ? Icons.check_circle : Icons.cancel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
