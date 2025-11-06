// lib/features/codigo_game/view/codigo_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // --- ¡CAMBIO 1! ---
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';

// --- ¡CAMBIO 2! (Importaciones para la puntuación) ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
// --- FIN CAMBIO 2 ---

// --- ¡CAMBIO 3! (Convertido a ConsumerStatefulWidget) ---
class CodigoChallengeView extends ConsumerStatefulWidget {
  final CodigoChallenge challenge;
  final String retoId;

  const CodigoChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
  });

  @override
  // --- ¡CAMBIO 4! ---
  ConsumerState<CodigoChallengeView> createState() => _CodigoChallengeViewState();
}

// --- ¡CAMBIO 5! (Convertido a ConsumerState) ---
class _CodigoChallengeViewState extends ConsumerState<CodigoChallengeView> {
  late final PageController _pageController;

  // ¡CAMBIO! Marcados como 'final' para corregir el 'lint'
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  int _currentPageIndex = 0;

  bool _mostrandoFeedback = false;
  bool _esRespuestaCorrecta = false;
  
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setupControllersAndFocusNodesForPage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _clearControllersAndFocusNodes(); 
    super.dispose();
  }

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

  void _setupControllersAndFocusNodesForPage(int pageIndex) {
    _clearControllersAndFocusNodes(); 

    if (pageIndex >= widget.challenge.preguntas.length) return;
    final pregunta = widget.challenge.preguntas[pageIndex];

    for (var fragmento in pregunta.fragmentos) {
      if (fragmento.tipo == 'input') {
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
      }
    }

    setState(() {
      _currentPageIndex = pageIndex;
    });

    if (_focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) { 
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  // --- ¡CORREGIDO! (Usando los parámetros correctos) ---
  Future<void> _submitAttempt(bool esCorrecto) async {
    if (_hasSubmitted) return; 
    _hasSubmitted = true; 

    final int retoIdAsInt;
    try {
      retoIdAsInt = int.parse(widget.retoId);
    } catch (e) {
      debugPrint("Error: retoId no es un número válido: ${widget.retoId}");
      return; 
    }

    try {
      final repository = ref.read(challengeRepositoryProvider);
      await repository.submitChallengeAttempt(
        retoId: retoIdAsInt,
        fueExitoso: esCorrecto,
        tiempoQueTardo: 0, 
      );

      ref.read(appBarProvider.notifier).fetchStats();
      ref.invalidate(globalRankingProvider);

    } catch (e) {
      debugPrint("Error al enviar intento de código: $e");
    }
  }

  Future<void> _verificarRespuesta() async {
    // ... (lógica de verificación) ...
    final preguntaActual = widget.challenge.preguntas[_currentPageIndex];
    final fragmentosInput = preguntaActual.fragmentos
        .where((f) => f.tipo == 'input')
        .toList();
    bool todasCorrectas = true;
    for (int i = 0; i < fragmentosInput.length; i++) {
      final respuestaUsuario = _controllers[i].text.trim();
      final respuestaCorrecta = fragmentosInput[i].valor.trim();
      if (respuestaUsuario != respuestaCorrecta) {
        todasCorrectas = false;
        break;
      }
    }
    // ... (fin lógica)

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
      // --- LÓGICA DE FALLO ---
      await _submitAttempt(false); 
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        // --- ¡ARREGLO DE CRASH! ---
        if (mounted) {
          Navigator.of(context).pop(); 
        }
        // --- FIN ARREGLO ---
      });
    }
  }

  Future<void> _siguientePregunta() async {
    if (_currentPageIndex < widget.challenge.preguntas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _mostrandoFeedback = false;
      });
    } else {
      // --- LÓGICA DE ÉXITO ---
      await _submitAttempt(true);
      
      // --- ¡ARREGLO DE CRASH! ---
      if (mounted) { 
          Navigator.of(context).pop();
      }
      // --- FIN ARREGLO ---
    }
  }

  // ... (El resto de tu código: _buildCodeSpans, build, _buildFeedbackContainer...)
  List<InlineSpan> _buildCodeSpans(
    CodigoPregunta pregunta,
    TextStyle codeStyle,
    TextStyle inputStyle,
  ) {
    final List<InlineSpan> spans = [];
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
          final int currentIndex = controllerIndex; 

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: IntrinsicWidth(
                child: TextField(
                  controller: _controllers[currentIndex],
                  focusNode:
                      _focusNodes[currentIndex], 
                  style: inputStyle,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.trim() == respuestasCorrectas[currentIndex]) {
                      if (currentIndex + 1 < _focusNodes.length) {
                        _focusNodes[currentIndex + 1].requestFocus();
                      } else {
                        _focusNodes[currentIndex].unfocus();
                      }
                    }
                  },
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
                _setupControllersAndFocusNodesForPage(newIndex);
              },
              itemBuilder: (context, index) {
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
          _buildFeedbackContainer(),
        ],
      ),
    );
  }

  Widget _buildFeedbackContainer() {
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