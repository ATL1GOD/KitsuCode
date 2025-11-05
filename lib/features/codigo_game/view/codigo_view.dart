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

  // --- ¡CAMBIOS IMPORTANTES (DE NUEVO)! ---
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes =
      []; // <-- AÑADIDO: Lista para los nodos de foco
  int _currentPageIndex = 0;
  // --- FIN CAMBIOS ---

  bool _mostrandoFeedback = false;
  bool _esRespuestaCorrecta = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setupControllersAndFocusNodesForPage(
      0,
    ); // <-- Nombre de función actualizado
  }

  @override
  void dispose() {
    _pageController.dispose();
    _clearControllersAndFocusNodes(); // <-- Nueva función helper de limpieza
    super.dispose();
  }

  // --- ¡NUEVA FUNCIÓN HELPER! ---
  // Limpia y "disposea" todos los controllers y focus nodes
  void _clearControllersAndFocusNodes() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }
  // --- FIN NUEVA FUNCIÓN ---

  // --- ¡FUNCIÓN MODIFICADA! ---
  // Ahora configura ambas listas
  void _setupControllersAndFocusNodesForPage(int pageIndex) {
    _clearControllersAndFocusNodes(); // Limpiamos los anteriores

    if (pageIndex >= widget.challenge.preguntas.length) return;
    final pregunta = widget.challenge.preguntas[pageIndex];

    for (var fragmento in pregunta.fragmentos) {
      if (fragmento.tipo == 'input') {
        _controllers.add(TextEditingController());
        _focusNodes.add(
          FocusNode(),
        ); // <-- AÑADIDO: Crea un FocusNode por cada input
      }
    }

    setState(() {
      _currentPageIndex = pageIndex;
    });

    // --- AÑADIDO ---
    // Da el foco al primer campo de texto automáticamente
    if (_focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes.first.requestFocus();
      });
    }
  }

  // --- ¡FUNCIÓN MODIFICADA! ---
  void _verificarRespuesta() {
    final preguntaActual = widget.challenge.preguntas[_currentPageIndex];

    final fragmentosInput = preguntaActual.fragmentos
        .where((f) => f.tipo == 'input')
        .toList();

    bool todasCorrectas = true;

    for (int i = 0; i < fragmentosInput.length; i++) {
      // --- ¡LÓGICA MEJORADA! ---
      // Se quita .toLowerCase() para que sea case-sensitive
      // Se mantiene .trim() para ignorar espacios al inicio/final
      final respuestaUsuario = _controllers[i].text.trim();
      final respuestaCorrecta = fragmentosInput[i].valor.trim();
      // --- FIN MEJORA ---

      if (respuestaUsuario != respuestaCorrecta) {
        todasCorrectas = false;
        break;
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
      setState(() {
        _mostrandoFeedback = false;
      });
    } else {
      Navigator.of(context).pop();
    }
    // NOTA: Los controllers y focus nodes se actualizan
    // gracias al 'onPageChanged' del PageView.
  }

  // --- ¡FUNCIÓN MODIFICADA! ---
  // Ahora construye los spans y asigna los focus nodes y el auto-avance
  List<InlineSpan> _buildCodeSpans(
    CodigoPregunta pregunta,
    TextStyle codeStyle,
    TextStyle inputStyle,
  ) {
    final List<InlineSpan> spans = [];
    // Obtenemos las respuestas correctas por adelantado
    final respuestasCorrectas = pregunta.fragmentos
        .where((f) => f.tipo == 'input')
        .map((f) => f.valor.trim())
        .toList();

    int controllerIndex = 0;

    for (var fragmento in pregunta.fragmentos) {
      if (fragmento.tipo == 'texto') {
        spans.add(TextSpan(text: fragmento.valor, style: codeStyle));
      } else if (fragmento.tipo == 'input') {
        if (controllerIndex < _controllers.length) {
          final int currentIndex = controllerIndex; // Captura el índice actual

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: IntrinsicWidth(
                child: TextField(
                  controller: _controllers[currentIndex],
                  focusNode:
                      _focusNodes[currentIndex], // <-- AÑADIDO: Asigna el FocusNode
                  // autofocus se maneja en _setupControllers...
                  style: inputStyle,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  // --- ¡NUEVA LÓGICA DE AUTO-AVANCE! ---
                  onChanged: (value) {
                    // Compara con la respuesta correcta (case-sensitive)
                    if (value.trim() == respuestasCorrectas[currentIndex]) {
                      // Si es correcta, mira si hay un siguiente campo
                      if (currentIndex + 1 < _focusNodes.length) {
                        // Si hay, mueve el foco a él
                        _focusNodes[currentIndex + 1].requestFocus();
                      } else {
                        // Si es el último campo, quita el foco (cierra el teclado)
                        _focusNodes[currentIndex].unfocus();
                      }
                    }
                  },
                  // --- FIN LÓGICA AUTO-AVANCE ---
                  onSubmitted: (_) => _verificarRespuesta(),
                ),
              ),
            ),
          );
          controllerIndex++;
        }
      }
    }
    return spans;
  }
  // --- FIN MODIFICACIÓN ---

  @override
  Widget build(BuildContext context) {
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
              onPageChanged: (newIndex) {
                // --- ¡MODIFICADO! ---
                // Llama a la nueva función
                _setupControllersAndFocusNodesForPage(newIndex);
              },
              itemBuilder: (context, index) {
                // Asegurarse de que el índice coincida con el estado
                if (index != _currentPageIndex) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                        child: RichText(
                          text: TextSpan(
                            children: _buildCodeSpans(
                              pregunta,
                              codeStyle,
                              inputStyle,
                            ),
                          ),
                        ),
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
