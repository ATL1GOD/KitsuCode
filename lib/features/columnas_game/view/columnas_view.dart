// lib/features/columnas_game/view/columnas_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';

// --- MODIFICACIÓN: Importación de tu snackbar personalizado ---
import 'package:kitsucode/shared/snackbar/snackbar.dart';
// --- FIN MODIFICACIÓN ---

// --- Importaciones para la puntuación ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- FUSIÓN: Se añade el import de TU lógica de animación (dxniel7) ---
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// --- NUEVO: Importaciones para el modal y el router ---
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;
import 'package:kitsucode/features/challenge/widgets/appbar_challenge.dart';
import 'package:kitsucode/features/challenge/widgets/exit_dialog.dart';

// --- FIN NUEVO ---

class ColumnsChallengeView extends ConsumerStatefulWidget {
  final ColumnsChallenge challenge;
  final String retoId;
  final String nivelId; // ← ¡AÑADIDO!

  const ColumnsChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
    required this.nivelId, // ← ¡AÑADIDO!
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

  // ... (Las funciones _setupItems, _onItemTapped, _triggerIncorrectAnimation,
  // y _showWinDialogAndSubmit son idénticas en ambos, se mantienen) ...

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
              _showWinDialogAndSubmit(); // <-- Llamada a la función de éxito
            });
          }
        } else if (_selectedItem == tappedItem) {
          _selectedItem = null;
        } else {
          _incorrectItem1 = _selectedItem;
          _incorrectItem2 = tappedItem;
          _selectedItem = null;
          _triggerIncorrectAnimation(); // <-- Llamada a la función de fallo
        }
      }
    });
  }

  Future<void> _triggerIncorrectAnimation() async {
    setState(() {
      _isIncorrect = true;
    });

    if (mounted) {
      _showFeedbackModal(false);
    }

    // Reseteamos el estado de error después del modal
    // (Esto se maneja ahora en onContinue del modal)
    // Ya no es necesario el 'Future.delayed' aquí
  }

  Future<void> _showWinDialogAndSubmit() async {
    if (mounted) {
      _showFeedbackModal(true);
    }
  }

  // --- NUEVO: Función helper de Tema ---
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
            challengeId: int.parse(widget.retoId),
            isCorrect: esCorrecto,
            // --- ¡¡TU LÓGICA DE 'onContinue'!! ---
            onContinue: () async {
              Navigator.of(
                ctx,
              ).pop(); // Cierra el modal usando el ctx del builder

              if (_hasSubmitted) return;
              _hasSubmitted = true;

              try {
                // 0. GUARDAR valores actuales (¡TU LÓGICA DE ANIMACIÓN!)
                final currentStats = ref.read(appBarProvider);
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
                final int nivelIdAsInt = int.parse(
                  widget.nivelId,
                ); // ← ¡AÑADIDO!

                if (esCorrecto) {
                  // 1. Enviar intento y OBTENER trofeos (¡TU LÓGICA DE TROFEOS!)
                  final int trofeos = await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt, // ← ¡AÑADIDO!
                    fueExitoso: true,
                    tiempoQueTardo: 0,
                  );

                  // 2. Refrescar ranking
                  ref.invalidate(globalRankingProvider);

                  // 3. Navegar CON TROFEOS
                  if (!context.mounted) return;
                  // ignore: use_build_context_synchronously
                  context.push('/challenge_success', extra: trofeos);
                } else {
                  // 1. Enviar intento fallido
                  await repository.submitChallengeAttempt(
                    retoId: retoIdAsInt,
                    nivelId: nivelIdAsInt, // ← ¡AÑADIDO!
                    fueExitoso: false,
                    tiempoQueTardo: 0,
                  );

                  // 2. Obtener recursos
                  final List<RecursoModel> recursos = widget.challenge.recursos;

                  // 3. Navegar
                  if (!context.mounted) return;
                  // ignore: use_build_context_synchronously
                  context.push('/challenge_failure', extra: recursos);
                }

                // Lógica extra para resetear el estado de error de columnas
                if (!esCorrecto && mounted) {
                  setState(() {
                    _isIncorrect = false;
                    _incorrectItem1 = null;
                    _incorrectItem2 = null;
                  });
                }
              } catch (e) {
                // Mostrar error al usuario
                if (context.mounted) {
                  // --- MODIFICACIÓN: Se usa el snackbar personalizado ---
                  showErrorSnackbar(
                    // ignore: use_build_context_synchronously
                    context,
                    'Error',
                    'Error al enviar resultado: $e',
                  );
                  // --- FIN MODIFICACIÓN ---
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
          onClose: () {
            showExitDialog(context, ref);
          },
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

  // --- FUSIÓN: Se usa el '_buildCheckButton' de ELLOS (theme-aware) ---
  Widget _buildCheckButton(bool isComplete, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: isComplete
            ? () {
                _showWinDialogAndSubmit();
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
