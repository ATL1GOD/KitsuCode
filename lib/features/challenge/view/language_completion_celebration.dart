import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitsucode/core/utils/app_themes.dart';

class LanguageCompletionCelebration extends StatefulWidget {
  final String languageName;
  final VoidCallback onContinue;

  const LanguageCompletionCelebration({
    super.key,
    required this.languageName,
    required this.onContinue,
  });

  @override
  State<LanguageCompletionCelebration> createState() =>
      _LanguageCompletionCelebrationState();
}

class _LanguageCompletionCelebrationState
    extends State<LanguageCompletionCelebration> {
  late ConfettiController _confettiController;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _confettiController.play();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

  IconData _getLanguageIcon() {
    switch (widget.languageName.toLowerCase()) {
      case 'python':
        return Icons.code;
      case 'java':
        return Icons.coffee;
      case 'c':
        return Icons.memory;
      default:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeTheme = _getLanguageTheme(
      widget.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;
    final textTheme = challengeTheme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  colorScheme.primary.withAlpha(77),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.yellow,
                Colors.green,
                Colors.blue,
              ],
            ),
          ),

          if (_showContent)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withAlpha(153),
                                colorScheme.primary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withAlpha(128),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            size: 120,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withAlpha(128),
                        )
                        .then()
                        .shake(hz: 0.5, duration: 1000.ms),

                    const SizedBox(height: 40),

                    Text(
                          '¡LENGUAJE DOMINADO!',
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: colorScheme.primary,
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .scale(delay: 300.ms)
                        .then()
                        .shimmer(duration: 1500.ms, color: colorScheme.primary),

                    const SizedBox(height: 16),

                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getLanguageIcon(),
                                color: colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.languageName.toUpperCase(),
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.3, end: 0, delay: 600.ms),

                    const SizedBox(height: 24),

                    Text(
                          '¡Eres todo un programador!\n¡Sigue así! 🦊',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withAlpha(179),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 900.ms)
                        .slideY(begin: 0.2, end: 0, delay: 900.ms),

                    const Spacer(),

                    SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: colorScheme.primary,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'CONTINUAR',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 1200.ms)
                        .slideY(begin: 0.3, end: 0, delay: 1200.ms)
                        .then(delay: 600.ms)
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withAlpha(77),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
