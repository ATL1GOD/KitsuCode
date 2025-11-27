// lib/features/columnas_game/view/columnas_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class ColumnsChallengeView extends ConsumerStatefulWidget {
  final ColumnsChallenge challenge;
  final String retoId;
  final String nivelId;
  
  // 🔥 Callback para modo Onboarding
  final Function(bool isCorrect)? onOnboardingFinished;

  const ColumnsChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
    required this.nivelId,
    this.onOnboardingFinished, // <-- AÑADIDO
  });

  @override
  ConsumerState<ColumnsChallengeView> createState() =>
      _ColumnsChallengeViewState();
}

class _ColumnsChallengeViewState extends ConsumerState<ColumnsChallengeView> {
  List<ChallengeItem> _items = [];
  ChallengeItem? _selectedItem;
  final Set<int> _solvedPairIds = {};
  bool _isIncorrect = false;
  ChallengeItem? _incorrectItem1;
  ChallengeItem? _incorrectItem2;

  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _setupItems();
  }

  void _setupItems() {
    final List<ChallengeItem> leftColumn = [];
    final List<ChallengeItem> rightColumn = [];
    final random = Random();

    for (var pair in widget.challenge.pares) {
      final terminoItem = ChallengeItem(
        pairId: pair.id,
        text: pair.termino,
        type: ItemType.termino,
      );
      final definicionItem = ChallengeItem(
        pairId: pair.id,
        text: pair.definicion,
        type: ItemType.definicion,
      );

      if (random.nextBool()) {
        leftColumn.add(terminoItem);
        rightColumn.add(definicionItem);
      } else {
        leftColumn.add(definicionItem);
        rightColumn.add(terminoItem);
      }
    }
    leftColumn.shuffle(random);
    rightColumn.shuffle(random);
    _items = [];
    for (int i = 0; i < leftColumn.length; i++) {
      _items.add(leftColumn[i]);
      _items.add(rightColumn[i]);
    }
  }

  void _onItemTapped(ChallengeItem tappedItem) {
    if (_solvedPairIds.contains(tappedItem.pairId) || _isIncorrect) {
      return;
    }

    setState(() {
      if (_selectedItem == null) {
        _selectedItem = tappedItem;
        _incorrectItem1 = null;
        _incorrectItem2 = null;
      } else {
        bool isCorrectPair =
            _selectedItem!.pairId == tappedItem.pairId &&
            _selectedItem!.type != tappedItem.type;

        if (isCorrectPair) {
          _solvedPairIds.add(tappedItem.pairId);
          _selectedItem = null;

          if (_solvedPairIds.length == widget.challenge.pares.length) {
            Future.delayed(const Duration(milliseconds: 300), () {
              // 🔥 LÓGICA DE ÉXITO
              if (!mounted) return;
              
              if (widget.onOnboardingFinished != null) {
                 widget.onOnboardingFinished!(true);
              } else {
                 _showWinDialogAndSubmit(); 
              }
            });
          }
        } else if (_selectedItem == tappedItem) {
          _selectedItem = null;
        } else {
          // 🔥 ERROR DETECTADO
          _incorrectItem1 = _selectedItem;
          _incorrectItem2 = tappedItem;
          _selectedItem = null;
          _triggerIncorrectAnimation(); // <-- Inicia la secuencia de fallo
        }
      }
    });
  }

  Future<void> _triggerIncorrectAnimation() async {
    setState(() {
      _isIncorrect = true; // Muestra rojo
    });

    // Esperamos 1 segundo para que el usuario vea el error visualmente
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 🔥 DECISIÓN FINAL (Modo Estricto)
    if (widget.onOnboardingFinished != null) {
        // En Onboarding: Se acabó, fallaste.
        widget.onOnboardingFinished!(false);
    } else {
        // En Juego Normal: Muestra modal de fallo
        _showFeedbackModal(false);
    }
    
    // Limpiamos la selección visual (por si acaso el usuario se queda o reintenta en otro contexto)
    if (mounted) {
      setState(() {
        _isIncorrect = false;
        _incorrectItem1 = null;
        _incorrectItem2 = null;
      });
    }
  }

  Future<void> _showWinDialogAndSubmit() async {
    if (mounted) {
      _showFeedbackModal(true);
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

    // 🔥 SEGURIDAD: Si por alguna razón llegamos aquí en onboarding, salimos.
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

  @override
  Widget build(BuildContext context) {
    double progress = _solvedPairIds.length / widget.challenge.pares.length;
    bool isComplete = progress == 1.0;

    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;

    return Theme(
      data: challengeTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: ChallengeAppBar2(
          progress: progress,
          // 🔥 FIX: Ocultar botón de cierre si es Onboarding
          onClose: widget.onOnboardingFinished != null 
              ? null 
              : () => showExitDialog(context, ref),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona los pares',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 55),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    key: const ValueKey('list_view'),
                    itemCount: (_items.length / 2).ceil(),
                    itemBuilder: (context, rowIndex) {
                      final leftIndex = rowIndex * 2;
                      final rightIndex = leftIndex + 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildItemChip(
                                  _items[leftIndex],
                                  colorScheme,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              if (rightIndex < _items.length)
                                Expanded(
                                  child: _buildItemChip(
                                    _items[rightIndex],
                                    colorScheme,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Botón Comprobar (En modo estricto puede no usarse, pero lo dejamos)
              _buildCheckButton(isComplete, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemChip(ChallengeItem item, ColorScheme colorScheme) {
    final bool isSolved = _solvedPairIds.contains(item.pairId);
    final bool isSelected = _selectedItem == item;
    final bool isMarkedIncorrect =
        _isIncorrect && (_incorrectItem1 == item || _incorrectItem2 == item);

    Color backgroundColor = colorScheme.surfaceContainer;
    Color borderColor = colorScheme.outline;
    Color textColor = colorScheme.onSurfaceVariant;
    double elevation = 2.0;
    FontWeight fontWeight = FontWeight.bold;

    if (isSolved) {
      backgroundColor = Colors.green.withAlpha(51);
      borderColor = Colors.green;
      textColor = Colors.green;
      elevation = 0.0;
    } else if (isMarkedIncorrect) {
      backgroundColor = Colors.red.withAlpha(51);
      borderColor = Colors.red;
      textColor = Colors.red;
      elevation = 2.0;
    } else if (isSelected) {
      backgroundColor = colorScheme.primaryContainer.withAlpha(77);
      borderColor = colorScheme.primary;
      textColor = colorScheme.primary;
      elevation = 4.0;
    }

    VoidCallback? onTap = isSolved ? null : () => _onItemTapped(item);

    return Material(
      elevation: elevation,
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.0),
      shadowColor: Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: borderColor, width: 2.5),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12.0,
              ),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton(bool isComplete, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: isComplete
            ? () {
                if (widget.onOnboardingFinished != null) {
                  widget.onOnboardingFinished!(true);
                } else {
                  _showWinDialogAndSubmit();
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isComplete ? 2 : 0,
        ),
        child: Text(
          'COMPROBAR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isComplete
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}