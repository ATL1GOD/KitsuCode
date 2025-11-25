import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget optimizado de tarjeta con efecto vidrio (glass effect).
///
/// Permite deshabilitar el costoso BackdropFilter cuando la vista
/// no está visible para mejorar el rendimiento GPU.
class OptimizedGlassCard extends StatelessWidget {
  final Widget child;

  /// Si es false, usa una versión más ligera sin BackdropFilter
  final bool enableGlassEffect;

  const OptimizedGlassCard({
    super.key,
    required this.child,
    this.enableGlassEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Colores adaptativos
    final Color cardColor;
    final Color borderColor;

    if (isDarkMode) {
      cardColor = colors.surfaceContainerHighest.withAlpha(153);
      borderColor = colors.outline.withAlpha(77);
    } else {
      cardColor = Colors.white.withAlpha(51);
      borderColor = colors.outline.withAlpha(51);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: enableGlassEffect
            ? BackdropFilter(
                // 🔥 Reducir blur de 8 a 5 para mejor rendimiento
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: child,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  // Versión más sólida sin blur cuando está deshabilitado
                  color: isDarkMode
                      ? colors.surfaceContainerHighest.withOpacity(0.85)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  // Sombra suave para mantener profundidad visual
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
      ),
    );
  }
}
