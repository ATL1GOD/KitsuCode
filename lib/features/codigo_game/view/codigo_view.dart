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

  // --- ¡CAMBIOS IMPORTANTES! ---
  // Ya no es un solo controller, sino una lista
  List<TextEditingController> _controllers = [];
  // Necesitamos saber qué página estamos viendo para configurar los controllers
  int _currentPageIndex = 0;
  // --- FIN CAMBIOS ---

  // Estado para la retroalimentación
  bool _mostrandoFeedback = false;
  bool _esRespuestaCorrecta = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Preparamos los controllers para la PRIMERA página (index 0)
    _setupControllersForPage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // ¡Importante! Limpiar todos los controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- ¡NUEVA FUNCIÓN! ---
  // Prepara la lista de controllers para una página específica
  void _setupControllersForPage(int pageIndex) {
    // 1. Limpia y "disposea" los controllers antiguos
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();

    // 2. Obtiene la pregunta para la página nueva
    if (pageIndex >= widget.challenge.preguntas.length) return;
    final pregunta = widget.challenge.preguntas[pageIndex];

    // 3. Crea un controller SOLO para los fragmentos de tipo "input"
    for (var fragmento in pregunta.fragmentos) {
      if (fragmento.tipo == 'input') {
        _controllers.add(TextEditingController());
      }
    }

    // 4. Actualiza el estado
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }
  // --- FIN NUEVA FUNCIÓN ---

  // --- ¡FUNCIÓN MODIFICADA! ---
  void _verificarRespuesta() {
    final preguntaActual = widget.challenge.preguntas[_currentPageIndex];

    // Obtenemos solo los fragmentos que son "input"
    final fragmentosInput = preguntaActual.fragmentos
        .where((f) => f.tipo == 'input')
        .toList();

    bool todasCorrectas = true;

    // Comparamos cada controller con su respuesta correcta
    for (int i = 0; i < fragmentosInput.length; i++) {
      final respuestaUsuario = _controllers[i].text.trim().toLowerCase();
      final respuestaCorrecta = fragmentosInput[i].valor.trim().toLowerCase();

      if (respuestaUsuario != respuestaCorrecta) {
        todasCorrectas = false;
        break; // Si una falla, no seguimos revisando
      }
    }

    setState(() {
      _esRespuestaCorrecta = todasCorrectas;
      _mostrandoFeedback = true;
    });

    if (todasCorrectas) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _siguientePregunta();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _mostrandoFeedback = false;
        });
      });
    }
  }

  void _siguientePregunta() {
    if (_currentPageIndex < widget.challenge.preguntas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // OJO: Los controllers se limpian y configuran
      // gracias al 'onPageChanged' del PageView.
      setState(() {
        _mostrandoFeedback = false;
      });
    } else {
      Navigator.of(context).pop(); // Fin del reto
    }
  }

  // --- ¡NUEVA FUNCIÓN! ---
  // Helper para construir la lista de TextSpans y WidgetSpans
  List<InlineSpan> _buildCodeSpans(
    CodigoPregunta pregunta,
    TextStyle codeStyle,
    TextStyle inputStyle,
  ) {
    final List<InlineSpan> spans = [];
    int controllerIndex = 0; // Para llevar la cuenta de qué controller usar

    for (var fragmento in pregunta.fragmentos) {
      if (fragmento.tipo == 'texto') {
        spans.add(TextSpan(text: fragmento.valor, style: codeStyle));
      } else if (fragmento.tipo == 'input') {
        // Asegurarnos de que el controller existe (sino, algo salió mal)
        if (controllerIndex < _controllers.length) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: IntrinsicWidth(
                child: TextField(
                  controller:
                      _controllers[controllerIndex], // Asigna el controller
                  autofocus: controllerIndex == 0, // Solo autofocus al primero
                  style: inputStyle,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  onSubmitted: (_) => _verificarRespuesta(),
                ),
              ),
            ),
          );
          controllerIndex++; // Pasamos al siguiente controller
        }
      }
    }
    return spans;
  }
  // --- FIN NUEVA FUNCIÓN ---

  @override
  Widget build(BuildContext context) {
    // Estilos (sin cambios)
    const codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: Colors.white,
      height: 1.5,
    );
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.challenge.preguntas.length,
              // --- ¡MODIFICADO! ---
              onPageChanged: (newIndex) {
                // Cuando la página cambia, preparamos los controllers para esa NUEVA página
                _setupControllersForPage(newIndex);
              },
              // --- FIN MODIFICACIÓN ---
              itemBuilder: (context, index) {
                final pregunta = widget.challenge.preguntas[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pregunta.instruccion,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        // --- ¡MODIFICADO! ---
                        // Usamos la nueva función para construir el RichText
                        child: RichText(
                          text: TextSpan(
                            children: _buildCodeSpans(
                              pregunta,
                              codeStyle,
                              inputStyle,
                            ),
                          ),
                        ),
                        // --- FIN MODIFICACIÓN ---
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          _buildFeedbackContainer(), // (Sin cambios)
        ],
      ),
    );
  }

  Widget _buildFeedbackContainer() {
    // ... (Esta función no necesita cambios)
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
