// lib/features/challenge/view/language_completion_flow.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/challenge/view/language_completion_celebration.dart';
import 'package:kitsucode/features/challenge/view/language_selection_view.dart';
import 'package:kitsucode/features/challenge/view/all_languages_completed_view.dart';

/// Flujo completo de completar un lenguaje
/// 1. Muestra celebración
/// 2. Muestra selección de nuevo lenguaje (SI PUEDE desbloquear)
/// 3. Vuelve al home (si YA usó este lenguaje para desbloquear)
/// 4. Muestra pantalla especial si completó TODOS los lenguajes
class LanguageCompletionFlow extends StatefulWidget {
  final String completedLanguage;
  final List<String> unlockedLanguages;
  final bool canUnlockNewLanguage; // 🆕 Si puede desbloquear otro

  const LanguageCompletionFlow({
    super.key,
    required this.completedLanguage,
    required this.unlockedLanguages,
    this.canUnlockNewLanguage = true, // Por defecto sí puede
  });

  @override
  State<LanguageCompletionFlow> createState() => _LanguageCompletionFlowState();
}

class _LanguageCompletionFlowState extends State<LanguageCompletionFlow> {
  bool _showingCelebration = true;

  @override
  void initState() {
    super.initState();
    
    // Si completó TODOS los lenguajes, ir directo a la pantalla especial
    if (widget.completedLanguage == 'ALL' || widget.unlockedLanguages.length >= 3) {
      _showingCelebration = false;
    }
  }

  void _onCelebrationComplete() {
    setState(() {
      _showingCelebration = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Caso especial: Completó TODOS los lenguajes
    if (widget.completedLanguage == 'ALL' || widget.unlockedLanguages.length >= 3) {
      return const AllLanguagesCompletedView();
    }

    // 🆕 NUEVO: Si completó pero YA NO puede desbloquear, solo celebración
    if (!widget.canUnlockNewLanguage) {
      return LanguageCompletionCelebration(
        languageName: widget.completedLanguage,
        onContinue: () {
          // Volver al home en lugar de selección
          Navigator.of(context).pop();
        },
      );
    }

    // Caso normal: Completó 1 lenguaje, PUEDE elegir otro
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _showingCelebration
          ? LanguageCompletionCelebration(
              key: const ValueKey('celebration'),
              languageName: widget.completedLanguage,
              onContinue: _onCelebrationComplete,
            )
          : LanguageSelectionView(
              key: const ValueKey('selection'),
              unlockedLanguages: widget.unlockedLanguages,
              currentLanguage: widget.completedLanguage,
            ),
    );
  }
}