import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class AchievementToast extends StatelessWidget {
  final String title;
  final String nombreLogro;
  final String iconUrl;
  final String raridad;
  final Color? borderColor;

  const AchievementToast({
    super.key,
    required this.title,
    required this.nombreLogro,
    required this.iconUrl,
    required this.raridad,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Color rarityColor = getRarityColor(raridad);
    final bool isDarkMode = colors.brightness == Brightness.dark;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      colors.surfaceContainerHighest,
                      colors.surfaceContainerLowest,
                    ]
                  : [colors.surfaceBright, colors.surfaceContainerHigh],
            ),
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: borderColor ?? rarityColor.withAlpha(128),
              width: 3,
            ),

            boxShadow: [
              BoxShadow(
                color: (borderColor ?? rarityColor).withAlpha(102),
                blurRadius: 15.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OptimizedImage(
                  imagePath: iconUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  enableCache: true,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,

                        color: borderColor ?? rarityColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreLogro,
                      style: TextStyle(color: colors.onSurface, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
