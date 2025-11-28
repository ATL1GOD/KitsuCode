import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_colors.dart'; // Asegúrate de importar tus colores si los necesitas

class OnboardingResultsView extends StatefulWidget {
  final int score;
  final String username;
  final String languageName;
  final VoidCallback onContinue;

  const OnboardingResultsView({
    super.key,
    required this.score,
    required this.username,
    required this.languageName,
    required this.onContinue,
  });

  @override
  State<OnboardingResultsView> createState() => _OnboardingResultsViewState();
}

class _OnboardingResultsViewState extends State<OnboardingResultsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Lógica para determinar el rango basado en el puntaje
  Map<String, dynamic> _getRankData() {
    if (widget.score > 70) {
      return {
        'title': 'Arquitecto de 9 Colas',
        'subtitle': '¡Nivel Legendario!',
        'desc': 'Tu conocimiento es vasto. El dojo espera grandes cosas de ti.',
        'icon': Icons.auto_awesome,
        'color': Colors.amber, // Dorado
      };
    } else if (widget.score > 30) {
      return {
        'title': 'Zorro Programador',
        'subtitle': '¡Nivel Avanzado!',
        'desc': 'Tienes instintos agudos para el código. ¡Sigue así!',
        'icon': Icons.code,
        'color': Colors.cyan, // Cyan tecnológico
      };
    } else {
      return {
        'title': 'Kitsu Aprendiz',
        'subtitle': '¡El viaje comienza!',
        'desc': 'Todo gran maestro comenzó escribiendo su primer "Hola Mundo".',
        'icon': Icons.pets,
        'color': Colors.orange, // Naranja zorro
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankData = _getRankData();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Animación del Icono / Rango
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: rankData['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankData['color'], width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: rankData['color'].withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    rankData['icon'],
                    size: 80,
                    color: rankData['color'],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Textos de Resultado (Fade In)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      "¡Felicidades, ${widget.username}!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Has sido clasificado como:",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rankData['title'],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: rankData['color'],
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      rankData['subtitle'],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        rankData['desc'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Estadísticas rápidas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatBadge(
                          context,
                          "Puntaje",
                          "${widget.score} pts",
                          Icons.star,
                        ),
                        const SizedBox(width: 16),
                        _buildStatBadge(
                          context,
                          "Lenguaje",
                          widget.languageName,
                          Icons.terminal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 3. Botón de Continuar
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
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
                      elevation: 4,
                    ),
                    child: const Text(
                      "COMENZAR AVENTURA",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
