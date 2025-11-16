// lib/features/challenge/view/language_completion_celebration.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class LanguageCompletionCelebration extends StatefulWidget {
  final String languageName; // "Python", "Java", "C"
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Iniciar confetti inmediatamente
    _confettiController.play();
    
    // Mostrar contenido después de un pequeño delay
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

  Color _getLanguageColor() {
    switch (widget.languageName.toLowerCase()) {
      case 'python':
        return const Color(0xFF3776AB);
      case 'java':
        return const Color(0xFFF89820);
      case 'c':
        return const Color(0xFF00599C);
      default:
        return Colors.orange;
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
    final size = MediaQuery.of(context).size;
    final languageColor = _getLanguageColor();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  languageColor.withValues(alpha: 0.3),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Confetti
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
                languageColor,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.red,
                Colors.purple,
              ],
            ),
          ),

          // Contenido principal
          if (_showContent)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Trofeo/Medalla animada
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            languageColor.withValues(alpha: 0.6),
                            languageColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: languageColor.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 120,
                        color: Colors.white,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5))
                        .then()
                        .shake(hz: 0.5, duration: 1000.ms),

                    const SizedBox(height: 40),

                    // Título principal
                    Text(
                      '¡LENGUAJE DOMINADO!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: languageColor,
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
                        .shimmer(duration: 1500.ms, color: languageColor),

                    const SizedBox(height: 16),

                    // Nombre del lenguaje
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: languageColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: languageColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getLanguageIcon(),
                            color: languageColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.languageName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: languageColor,
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

                    // Mensaje motivador
                    Text(
                      '¡Eres todo un programador!\n¡Sigue así! 🦊',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 900.ms)
                        .slideY(begin: 0.2, end: 0, delay: 900.ms),

                    const Spacer(),

                    // Botón de continuar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: languageColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: languageColor,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUAR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 24),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 1200.ms)
                        .slideY(begin: 0.3, end: 0, delay: 1200.ms)
                        .then(delay: 600.ms)
                        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}