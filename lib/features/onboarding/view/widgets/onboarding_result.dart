import 'package:flutter/material.dart';
import 'package:kitsucode/features/onboarding/model/onboarding_model.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class OnboardingResultsView extends StatefulWidget {
  final int score;
  final String username;
  final String languageName;
  final OnboardingResultModel resultModel;
  final VoidCallback onContinue;

  const OnboardingResultsView({
    super.key,
    required this.score,
    required this.username,
    required this.languageName,
    required this.resultModel,
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

  // Helper para imagen local (logo del lenguaje, estos sí son assets locales)
  String _getLanguageAsset(String name) {
    final n = name.toLowerCase();
    if (n.contains('python')) return 'assets/images/home/logo_python.webp';
    if (n.contains('java')) return 'assets/images/home/logo_java.webp';
    if (n.contains('c') || n == 'c') return 'assets/images/home/logo_c.webp';
    return '';
  }

  String _extractPath(String urlOrPath) {
    if (urlOrPath.contains('/public/assets/')) {
      return urlOrPath.split('/public/assets/').last;
    }
    return urlOrPath;
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.resultModel;
    final theme = Theme.of(context);

    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final colorScheme = theme.colorScheme;

    final langAsset = _getLanguageAsset(widget.languageName);

    final cleanImagePath = _extractPath(model.imagenUrl);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: OptimizedImage(
                      imagePath:
                          cleanImagePath, // Ruta limpia (ej: "rango.webp")
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      enableCache: true, // Importante para rendimiento
                      isLocalAsset:
                          false, // FALSE = Descarga de Supabase Storage
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- TEXTOS ---
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      "¡Felicidades, ${widget.username}!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
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

                    // Título del Rango
                    Text(
                      model.titulo,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),

                    // Subtítulo del Rango
                    Text(
                      model.subtitulo,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Descripción
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        model.descripcion,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Badges de estadísticas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatBadge(
                          context,
                          "Puntaje",
                          "${widget.score}",
                          icon: Icons.star,
                        ),
                        const SizedBox(width: 16),
                        _buildStatBadge(
                          context,
                          "Lenguaje",
                          widget.languageName,
                          imageAsset: langAsset.isNotEmpty ? langAsset : null,
                          icon: langAsset.isEmpty ? Icons.terminal : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // --- BOTÓN CONTINUAR ---
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.5),
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
    String value, {
    IconData? icon,
    String? imageAsset,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null)
            OptimizedImage(
              imagePath: imageAsset,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              isLocalAsset: true, // TRUE = Carga desde assets de la app
            )
          else if (icon != null)
            Icon(icon, size: 20, color: primaryColor),
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
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
