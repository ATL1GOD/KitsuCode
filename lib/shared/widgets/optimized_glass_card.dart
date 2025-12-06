import 'dart:ui';
import 'package:flutter/material.dart';

class OptimizedGlassCard extends StatelessWidget {
  final Widget child;

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
                  color: isDarkMode
                      ? colors.surfaceContainerHighest.withOpacity(0.85)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),

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
