import 'package:flutter/material.dart';
import 'package:kitsucode/features/challenge/view/language_completion_celebration.dart';
import 'package:kitsucode/features/challenge/view/language_selection_view.dart';
import 'package:kitsucode/features/challenge/view/all_languages_completed_view.dart';

class LanguageCompletionFlow extends StatefulWidget {
  final String completedLanguage;
  final List<String> unlockedLanguages;
  final bool canUnlockNewLanguage;

  const LanguageCompletionFlow({
    super.key,
    required this.completedLanguage,
    required this.unlockedLanguages,
    this.canUnlockNewLanguage = true,
  });

  @override
  State<LanguageCompletionFlow> createState() => _LanguageCompletionFlowState();
}

class _LanguageCompletionFlowState extends State<LanguageCompletionFlow> {
  bool _showingCelebration = true;

  @override
  void initState() {
    super.initState();

    if (widget.completedLanguage == 'ALL' ||
        widget.unlockedLanguages.length >= 3) {
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
    if (widget.completedLanguage == 'ALL' ||
        widget.unlockedLanguages.length >= 3) {
      return const AllLanguagesCompletedView();
    }

    if (!widget.canUnlockNewLanguage) {
      return LanguageCompletionCelebration(
        languageName: widget.completedLanguage,
        onContinue: () {
          Navigator.of(context).pop();
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
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
