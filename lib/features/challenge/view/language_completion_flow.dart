// lib/features/challenge/view/language_completion_flow.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/challenge/view/language_completion_celebration.dart';
import 'package:kitsucode/features/challenge/view/language_selection_view.dart';

/// Flujo completo de completar un lenguaje
/// 1. Muestra celebración
/// 2. Muestra selección de nuevo lenguaje
class LanguageCompletionFlow extends StatefulWidget {
  final String completedLanguage;
  final List<String> unlockedLanguages;

  const LanguageCompletionFlow({
    super.key,
    required this.completedLanguage,
    required this.unlockedLanguages,
  });

  @override
  State<LanguageCompletionFlow> createState() => _LanguageCompletionFlowState();
}

class _LanguageCompletionFlowState extends State<LanguageCompletionFlow> {
  bool _showingCelebration = true;

  void _onCelebrationComplete() {
    setState(() {
      _showingCelebration = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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