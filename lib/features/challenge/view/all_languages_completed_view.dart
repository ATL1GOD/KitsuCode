// lib/features/challenge/view/all_languages_completed_view.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class AllLanguagesCompletedView extends StatefulWidget {
  const AllLanguagesCompletedView({super.key});

  @override
  State<AllLanguagesCompletedView> createState() =>
      _AllLanguagesCompletedViewState();
}

class _AllLanguagesCompletedViewState extends State<AllLanguagesCompletedView> {
  late ConfettiController _confettiController;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Iniciar confetti
    _confettiController.play();
    
    // Mostrar contenido
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con gradiente animado
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.purple.withValues(alpha: 0.4),
                  Colors.blue.withValues(alpha: 0.3),
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
              emissionFrequency: 0.03,
              numberOfParticles: 70,
              gravity: 0.08,
              shouldLoop: true,
              colors: [
                Colors.purple,
                Colors.blue,
                Colors.cyan,
                Colors.yellow,
                Colors.green,
                Colors.red,
                Colors.orange,
                Colors.pink,
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

                    // Corona gigante
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade300,
                            Colors.orange.shade600,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 50,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 140,
                        color: Colors.white,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                            duration: 1500.ms,
                            color: Colors.white.withValues(alpha: 0.5))
                        .then()
                        .rotate(duration: 2000.ms, begin: -0.02, end: 0.02)
                        .then()
                        .rotate(duration: 2000.ms, begin: 0.02, end: -0.02),

                    const SizedBox(height: 50),

                    // Título épico
                    Text(
                      '¡MAESTRO DE LA\nPROGRAMACIÓN!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.purple.shade300,
                            blurRadius: 30,
                          ),
                          Shadow(
                            color: Colors.blue.shade300,
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .scale(delay: 300.ms)
                        .then()
                        .shimmer(
                            duration: 2000.ms,
                            color: Colors.white.withValues(alpha: 0.3)),

                    const SizedBox(height: 30),

                    // Badges de lenguajes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LanguageBadge(
                          icon: Icons.memory,
                          label: 'C',
                          color: const Color(0xFF00599C),
                          delay: 600,
                        ),
                        const SizedBox(width: 16),
                        _LanguageBadge(
                          icon: Icons.coffee,
                          label: 'Java',
                          color: const Color(0xFFF89820),
                          delay: 800,
                        ),
                        const SizedBox(width: 16),
                        _LanguageBadge(
                          icon: Icons.code,
                          label: 'Python',
                          color: const Color(0xFF3776AB),
                          delay: 1000,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Mensaje motivador
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🎉 ¡FELICITACIONES! 🎉',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Has dominado los 3 lenguajes de programación.\n'
                            '¡Eres un verdadero programador profesional!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 1200.ms)
                        .slideY(begin: 0.2, end: 0, delay: 1200.ms),

                    const Spacer(),

                    // Botón de continuar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.purple,
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
                        .fadeIn(duration: 600.ms, delay: 1500.ms)
                        .slideY(begin: 0.3, end: 0, delay: 1500.ms)
                        .then(delay: 600.ms)
                        .shimmer(
                            duration: 2000.ms,
                            color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;

  const _LanguageBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .scale(delay: delay.ms)
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}