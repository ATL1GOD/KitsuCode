// lib/features/columnas_game/view/columnas_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';

// --- Importaciones para la puntuación ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// --- NUEVO: Importaciones para el modal y el router ---
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;
// --- FIN NUEVO ---

class ColumnsChallengeView extends ConsumerStatefulWidget {
  final ColumnsChallenge challenge;
  final String retoId;

  const ColumnsChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
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
    // ... (Tu función _setupItems no cambia) ...
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

  // Future<void> _submitAttempt(bool esCorrecto) async {
  //   if (_hasSubmitted) return;
  //   _hasSubmitted = true;
    
  //   final int retoIdAsInt;
  //   try {
  //     retoIdAsInt = int.parse(widget.retoId);
  //   } catch (e) {
  //     debugPrint("Error: retoId no es un número válido: ${widget.retoId}");
  //     return; 
  //   }

  //   try {
  //     final repository = ref.read(challengeRepositoryProvider);
  //     await repository.submitChallengeAttempt(
  //       retoId: retoIdAsInt,
  //       fueExitoso: esCorrecto,
  //       tiempoQueTardo: 0,
  //     );

  //     ref.read(appBarProvider.notifier).fetchStats();
  //     ref.invalidate(globalRankingProvider);

  //   } catch (e) {
  //     debugPrint("Error al enviar intento de columnas: $e");
  //   }
  // }


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

  // --- MODIFICADO: Lógica de fallo ---
  Future<void> _triggerIncorrectAnimation() async {
    setState(() {
      _isIncorrect = true;
    });

    // --- MODIFICADO: Solo mostramos el modal ---
    if (mounted) {
      _showFeedbackModal(false);
    }
  }
  // --- FIN MODIFICADO ---

 // --- MODIFICADO: Lógica de éxito ---
  Future<void> _showWinDialogAndSubmit() async {
    // --- MODIFICADO: Solo mostramos el modal ---
    if (mounted) {
      _showFeedbackModal(true);
    }
  }
  // --- FIN MODIFICADO ---

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
              _hasSubmitted = true;

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

                // 3. Obtener recursos del widget
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


  @override
  Widget build(BuildContext context) {
    // ... (Tu función build no cambia) ...
    double progress = _solvedPairIds.length / widget.challenge.pares.length;
    bool isComplete = progress == 1.0;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                        minHeight: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.flash_on, color: Colors.pink, size: 20),
                  const Text(
                    ' ∞',
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona los pares', 
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3C3C), 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 55),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  key: const ValueKey('grid_view'), 
                  itemCount: _items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 2.8, 
                    crossAxisSpacing: 12.0, 
                    mainAxisSpacing: 30.0, 
                  ),
                  itemBuilder: (context, index) {
                    return _buildItemChip(_items[index]);
                  },
                ),
              ),
            ),
            _buildCheckButton(isComplete),
          ],
        ),
      ),
    );
  }

  Widget _buildItemChip(ChallengeItem item) {
    // ... (Tu función _buildItemChip no cambia) ...
    final bool isSolved = _solvedPairIds.contains(item.pairId);
    final bool isSelected = _selectedItem == item;
    final bool isMarkedIncorrect =
        _isIncorrect && (_incorrectItem1 == item || _incorrectItem2 == item);

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = const Color(0xFF585858);
    double elevation = 2.0;
    FontWeight fontWeight = FontWeight.bold;

    if (isSolved) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green;
      textColor = Colors.green.shade700;
      elevation = 0.0;
    } else if (isMarkedIncorrect) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red;
      textColor = Colors.red.shade700;
      elevation = 2.0;
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
      textColor = Colors.blue.shade700;
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
          width: double.infinity, 
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ), 
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton(bool isComplete) {
    // ... (Tu función _buildCheckButton no cambia) ...
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
          backgroundColor: isComplete ? Colors.green : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
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
            color: isComplete ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}