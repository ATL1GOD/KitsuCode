// lib/features/codigo_game/view/codigo_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';

// --- Importaciones para la puntuación y navegación ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// --- FUSIÓN: Se añade el import de TU lógica de animación (dxniel7) ---
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
// --- FIN FUSIÓN ---

// --- NUEVO: Importaciones para el modal y el router ---
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
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
  ConsumerState<CodigoChallengeView> createState() =>
      _CodigoChallengeViewState();
}

class _CodigoChallengeViewState extends ConsumerState<CodigoChallengeView> {
  late final PageController _pageController;

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  int _currentPageIndex = 0;

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

  // ... (Las funciones _clearControllersAndFocusNodes, _setupControllersAndFocusNodesForPage,
  // _verificarRespuesta, y _siguientePregunta son idénticas en ambos archivos,
  // así que las dejamos tal cual) ...
  
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
        if (mounted) {
          _focusNodes.first.requestFocus();
        }
      });
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

    if (todasCorrectas) {
      _siguientePregunta();
    } else {
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


  // --- FUSIÓN: Se usa TU '_showFeedbackModal' (dxniel7) ---
  // ¡¡Esta es la lógica CORRECTA!!
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
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Theme(
          data: challengeTheme,
          child: ChallengeFeedbackModal(
            isCorrect: esCorrecto,
            // --- ¡¡TU LÓGICA DE 'onContinue'!! ---
            onContinue: () async {
              Navigator.of(ctx).pop(); // Cierra el modal usando el ctx del builder
              
              if (_hasSubmitted) return;
              _hasSubmitted = true; // Marcamos como enviado

              try {
                // 0. GUARDAR valores actuales (¡TU LÓGICA DE ANIMACIÓN!)
                final currentStats = ref.read(appBarProvider);
                print("📊 Codigo - Guardando valores VIEJOS: vidas=${currentStats.lives}, trofeos=${currentStats.trophies}, racha=${currentStats.streak}");
                
                // ignore: use_of_void_result
                ref.read(oldStatsValuesProvider.notifier).state = [
                  currentStats.lives,
                  currentStats.trophies,
                  currentStats.streak,
                ];
                
                // Marcar flag (¡TU LÓGICA DE ANIMACIÓN!)
                markForStatsRefresh(ref);

                final repository = ref.read(challengeRepositoryProvider);
                final int retoIdAsInt = int.parse(widget.retoId);

                print("🎮 Codigo: Enviando resultado a Supabase (correcto: $esCorrecto)");

                if (esCorrecto) {
                  // 1. Enviar intento y OBTENER trofeos (¡TU LÓGICA DE TROFEOS!)
                  final int trofeos = await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    fueExitoso: true,
                    tiempoQueTardo: 0, 
                  );
                  
                  print("🏆 Trofeos obtenidos: $trofeos");
                  
                  // 2. Refrescar ranking
                  ref.invalidate(globalRankingProvider);
                  
                  // 3. Navegar CON TROFEOS
                  if (!context.mounted) return;
                  context.push('/challenge_success', extra: trofeos);
                
                } else {
                  // 1. Enviar intento fallido
                  await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    fueExitoso: false,
                    tiempoQueTardo: 0,
                  );

                  print("❌ Intento fallido enviado");

                  // 2. Obtener recursos
                  final List<RecursoModel> recursos = widget.challenge.recursos;
                  
                  // 3. Navegar
                  if (!context.mounted) return;
                  context.push('/challenge_failure', extra: recursos);
                }
              } catch (e, stackTrace) {
                print("❌ Error en onContinue (Codigo): $e");
                print("Stack trace: $stackTrace");
                
                // Mostrar error al usuario
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al enviar resultado: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            // --- FIN DE TU LÓGICA ---
          ),
        );
      },
    );
  }
  // --- FIN FUSIÓN ---


  // --- FUSIÓN: Se usa el '_buildCodeSpans' de ELLOS (theme-aware) ---
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
                  focusNode: _focusNodes[currentIndex],
                  style: inputStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        // ¡Usa el color del tema!
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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
  // --- FIN FUSIÓN ---


  @override
  Widget build(BuildContext context) {
    // --- FUSIÓN: Se usa el 'build' de ELLOS (theme-aware) ---
    
    // 1. Obtenemos el estado del AppBar
    final appBarState = ref.watch(appBarProvider);

    // 2. Usamos la función helper
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );

    // 3. Extraemos el esquema de color
    final colorScheme = challengeTheme.colorScheme;
    // --- FIN LÓGICA DE TEMA ---

    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: colorScheme.onSurface, // ¡Usa el color del tema!
      height: 1.5,
    );
    final inputStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: colorScheme.secondary, // ¡Usa el color del tema!
      fontWeight: FontWeight.bold,
      height: 1.5,
    );

    return Theme( // <-- Envolver aquí
      data: challengeTheme,
      child: Scaffold(
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
                            // ¡Usa el color del tema!
                            color: colorScheme.surfaceContainerHighest,
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
            // --- Botón de Verificar (sin cambios, ya usa el tema) ---
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
          ],
        ),
      ),
    );
  }
}