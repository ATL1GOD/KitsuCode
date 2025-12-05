// lib/features/codigo_game/view/codigo_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_instruction_card.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class CodigoChallengeView extends ConsumerStatefulWidget {
  final CodigoChallenge challenge;
  final String retoId;
  final String nivelId;
  final Function(bool isCorrect)? onOnboardingFinished;

  const CodigoChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
    required this.nivelId,
    this.onOnboardingFinished,
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
  late final int _totalInputsDelChallenge;
  int _inputsCompletadosEnPaginasAnteriores = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _totalInputsDelChallenge = widget.challenge.preguntas
        .expand((pregunta) => pregunta.fragmentos)
        .where((fragmento) => fragmento.tipo == 'input')
        .length;
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
        if (mounted) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  Future<void> _verificarRespuesta() async {
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

    if (todasCorrectas) {
      _siguientePregunta();
    } else {
      // 🔥 FIX: Error inmediato con protección anti-crash
      if (mounted) {
        if (widget.onOnboardingFinished != null) {
           widget.onOnboardingFinished!(false);
        } else {
           _showFeedbackModal(false);
        }
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
        // Todas correctas, terminó el juego
        if (widget.onOnboardingFinished != null) {
           widget.onOnboardingFinished!(true);
        } else {
           _showFeedbackModal(true);
        }
      }
    }
  }

  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
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

  void _showFeedbackModal(bool esCorrecto) {
    if (_hasSubmitted) return;

    // 🔥 Si es Onboarding, el control ya se manejó arriba en _verificarRespuesta.
    // Esta función solo debería correr en modo normal.
    if (widget.onOnboardingFinished != null) {
      widget.onOnboardingFinished!(esCorrecto);
      return;
    }

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
            challengeId: int.parse(widget.retoId),
            isCorrect: esCorrecto,
            onContinue: () async {
              Navigator.of(ctx).pop();

              if (_hasSubmitted) return;
              _hasSubmitted = true;

              try {
                final currentStats = ref.read(appBarProvider);
                ref.read(oldStatsValuesProvider.notifier).state = [
                  currentStats.lives,
                  currentStats.trophies,
                  currentStats.streak,
                ];

                markForStatsRefresh(ref);

                final repository = ref.read(challengeRepositoryProvider);
                final int retoIdAsInt = int.parse(widget.retoId);
                final int nivelIdAsInt = int.parse(widget.nivelId);

                if (esCorrecto) {
                  final int trofeos = await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt,
                    fueExitoso: true,
                    tiempoQueTardo: 0,
                  );
                  ref.invalidate(globalRankingProvider);
                  ref.invalidate(desafiosProvider);

                  if (!context.mounted) return;
                  context.push('/challenge_success', extra: trofeos);
                } else {
                  await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt,
                    fueExitoso: false,
                    tiempoQueTardo: 0,
                  );
                  final List<RecursoModel> recursos = widget.challenge.recursos;

                  if (!context.mounted) return;
                  context.push('/challenge_failure', extra: recursos);
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackbar(
                    context,
                    'Error',
                    'Error al enviar resultado: $e',
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  // ... (buildCodeSpans sin cambios)
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
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});

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
    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;

    final int inputsCompletadosPaginaActual = _controllers
        .where((controller) => controller.text.isNotEmpty)
        .length;
    final int totalCompletados =
        _inputsCompletadosEnPaginasAnteriores + inputsCompletadosPaginaActual;
    final double progress = _totalInputsDelChallenge > 0
        ? (totalCompletados / _totalInputsDelChallenge)
        : 0.0;

    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: colorScheme.onSurface,
      height: 1.5,
    );
    final inputStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 16,
      color: colorScheme.secondary,
      fontWeight: FontWeight.bold,
      height: 1.5,
    );

    return Theme(
      data: challengeTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        // 🔥 En onboarding, no redimensionar cuando aparece el teclado
        resizeToAvoidBottomInset: widget.onOnboardingFinished == null,
        appBar: ChallengeAppBar2(
          progress: progress,
          // 🔥 FIX: Ocultar botón cerrar en Onboarding
          onClose: widget.onOnboardingFinished != null
              ? null
              : () => showExitDialog(context, ref),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.challenge.preguntas.length,
                onPageChanged: (newIndex) {
                  if (newIndex > _currentPageIndex) {
                    final preguntaAnterior =
                        widget.challenge.preguntas[_currentPageIndex];
                    _inputsCompletadosEnPaginasAnteriores += preguntaAnterior
                        .fragmentos
                        .where((f) => f.tipo == 'input')
                        .length;
                  }
                  _setupControllersAndFocusNodesForPage(newIndex);
                },
                itemBuilder: (context, index) {
                  if (index != _currentPageIndex) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final pregunta = widget.challenge.preguntas[index];

                  // 🔥 Si es onboarding, deshabilitar scroll para evitar desplazamiento con teclado
                  final isOnboarding = widget.onOnboardingFinished != null;
                  
                  return SingleChildScrollView(
                    physics: isOnboarding ? const NeverScrollableScrollPhysics() : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 300),
                          child: PuzzleInstructionCard(
                            text: pregunta.instruccion,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeIn(
                          duration: const Duration(milliseconds: 300),
                          delay: const Duration(milliseconds: 150),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
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
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SlideInUp(
          duration: const Duration(milliseconds: 250),
          from: 100,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
              ),
            ),
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
        ),
      ),
    );
  }
}