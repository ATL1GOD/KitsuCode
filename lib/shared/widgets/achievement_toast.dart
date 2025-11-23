import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart'; // ¡Ya tenemos este helper!
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class AchievementToast extends StatelessWidget {
  final String title; // <-- 1. AÑADIDO: Título dinámico
  final String nombreLogro; // Sigue siendo el subtítulo
  final String iconUrl;
  final String raridad;
  final Color? borderColor;

  const AchievementToast({
    super.key,
    required this.title, // <-- 2. AÑADIDO: Título requerido
    required this.nombreLogro,
    required this.iconUrl,
    required this.raridad,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // El color de rareza se usa como fallback y para el "aura"
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
                      colors.surfaceContainerHighest, // Gris oscuro
                      colors.surfaceContainerLowest, // Negro
                    ]
                  : [
                      colors.surfaceBright, // Blanco brillante (#FDFDFD)
                      colors.surfaceContainerHigh, // Gris suave (#EDEDED)
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            // ✅ 3. BORDE ACTUALIZADO
            border: Border.all(
              // Usará el 'borderColor' (tu color primario) si existe.
              // Si no, usará el color de rareza como antes.
              color: borderColor ?? rarityColor.withAlpha(128),
              width: 3, // <-- Aumentado a 3px para que se note
            ),
            // 4. ¡EL AURA! (BoxShadow mejorado)
            boxShadow: [
              BoxShadow(
                // Usa el borderColor (si existe) o el color de rareza para el aura
                color: (borderColor ?? rarityColor).withAlpha(102),
                blurRadius: 15.0, // Más difuminada
                spreadRadius: 2.0, // Un poco más grande
              ),
            ],
          ),
          child: Row(
            children: [
              // --- El Icono ---
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

              // --- El Texto ---
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ 5. TÍTULO ACTUALIZADO
                    Text(
                      title, // <-- Usa la variable 'title'
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        // El color del título será el del borde (o el de rareza)
                        color: borderColor ?? rarityColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreLogro, // Este es el nombre del avatar/logro
                      style: TextStyle(
                        color: colors.onSurface, // Texto normal
                        fontSize: 14,
                      ),
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
