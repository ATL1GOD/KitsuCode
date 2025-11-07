// lib/features/codigo_game/view/codigo_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';

// --- Importaciones para la puntuación y navegación ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// --- NUEVO: Importaciones para el modal y el router ---
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;
// --- FIN NUEVO ---

class CodigoChallengeView extends ConsumerStatefulWidget {
  final CodigoChallenge challenge;
  final String retoId;

  const CodigoChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
  });

  @override
  ConsumerState<CodigoChallengeView> createState() => _CodigoChallengeViewState();
}

class _CodigoChallengeViewState extends ConsumerState<CodigoChallengeView> {
  late final PageController _pageController;

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  int _currentPageIndex = 0;

  // --- MODIFICADO: Ya no necesitamos estos estados ---
  // bool _mostrandoFeedback = false;
  // bool _esRespuestaCorrecta = false;
  // --- FIN MODIFICADO ---
  
  bool _hasSubmitted = false;
  bool _currentAnswerWasCorrect = false; // Para saber qué modal mostrar

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

//  Future<void> _submitAttempt(bool esCorrecto) async {
//     if (_hasSubmitted) return; 
//     _hasSubmitted = true; 

//     final int retoIdAsInt;
//     try {
//       retoIdAsInt = int.parse(widget.retoId);
//     } catch (e) {
//       debugPrint("Error: retoId no es un número válido: ${widget.retoId}");
//       return; 
//     }

//     try {
//       final repository = ref.read(challengeRepositoryProvider);
//       await repository.submitChallengeAttempt(
//         retoId: retoIdAsInt,
//         fueExitoso: esCorrecto,
//         tiempoQueTardo: 0, 
//       );

//       ref.read(appBarProvider.notifier).fetchStats();
//       ref.invalidate(globalRankingProvider);

//     } catch (e) {
//       debugPrint("Error al enviar intento de código: $e");
//     }
//   } 

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

    // --- MODIFICADO: Lógica de feedback ---
    _currentAnswerWasCorrect = todasCorrectas;

    if (todasCorrectas) {
      _siguientePregunta();
    } else {
      // --- MODIFICADO: Solo mostramos el modal de fallo ---
      if (mounted) {
        _showFeedbackModal(false);
      }
    }
  }

  Future<void> _siguientePregunta() async {
    if (_currentPageIndex < widget.challenge.preguntas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // --- MODIFICADO: Solo mostramos el modal de éxito ---
      if (mounted) { 
        _showFeedbackModal(true);
      }
    }
  }

  // --- NUEVO: Función helper de Tema (Copiada de puzzle_view) ---
  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // Asumiendo que tienes AppThemes.
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
  // --- FIN NUEVO ---

  // --- NUEVO: Función para mostrar el modal genérico ---
  // --- ¡¡AQUÍ ESTÁ LA MAGIA!! ---
  void _showFeedbackModal(bool esCorrecto) {
    // Evita múltiples envíos si el usuario es muy rápido
    if (_hasSubmitted) return;
    
    final appBarState = ref.read(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Theme(
          data: challengeTheme,
          child: ChallengeFeedbackModal(
            isCorrect: esCorrecto,
            // --- MODIFICADO: Lógica de onContinue ---
            onContinue: () async {
              context.pop(); // Cierra el modal
              
              if (_hasSubmitted) return;
              _hasSubmitted = true; // Marcamos como enviado

              final repository = ref.read(challengeRepositoryProvider);
              final int retoIdAsInt = int.parse(widget.retoId);

              if (esCorrecto) {
                // 1. Enviar intento y obtener trofeos
                final int trofeos = await repository.submitChallengeAttempt(
                  retoId: retoIdAsInt,
                  fueExitoso: true,
                  tiempoQueTardo: 0, 
                );
                
                // 2. Refrescar stats y ranking
                ref.read(appBarProvider.notifier).fetchStats();
                ref.invalidate(globalRankingProvider);
                
                // 3. Navegar
                if (!context.mounted) return;
                context.push('/challenge_success', extra: trofeos);
              
              } else {
                // 1. Enviar intento fallido
                 await repository.submitChallengeAttempt(
                  retoId: retoIdAsInt,
                  fueExitoso: false,
                  tiempoQueTardo: 0,
                );

                // 2. Refrescar stats (vidas)
                ref.read(appBarProvider.notifier).fetchStats();

                // 3. Obtener recursos del widget (ya cargados en el modelo)
                final List<RecursoModel> recursos = widget.challenge.recursos;
                
                // 4. Navegar
                if (!context.mounted) return;
                context.push('/challenge_failure', extra: recursos);
              }
            },
            // --- FIN MODIFICACIÓN ---
          ),
        );
      },
    );
  }
  // --- FIN NUEVO ---


  List<InlineSpan> _buildCodeSpans(
    CodigoPregunta pregunta,
    TextStyle codeStyle,
    TextStyle inputStyle,
  ) {
    // ... (Tu función _buildCodeSpans no cambia) ...
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
          // --- MODIFICADO: Reemplazamos el feedback container por un botón ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verificarRespuesta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'VERIFICAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // --- FIN MODIFICADO ---
        ],
      ),
    );
  }

  // --- MODIFICADO: Esta función ya no es necesaria ---
  // Widget _buildFeedbackContainer() { ... }
  // --- FIN MODIFICADO ---
}