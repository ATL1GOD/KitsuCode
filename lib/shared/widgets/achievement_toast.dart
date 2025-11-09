import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart'; // ¡Ya tenemos este helper!

class AchievementToast extends StatelessWidget {
  final String nombreLogro;
  final String iconUrl;
  final String raridad; 

  const AchievementToast({
    super.key,
    required this.nombreLogro,
    required this.iconUrl,
    required this.raridad,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color rarityColor = getRarityColor(raridad); // Nuestro helper de colores
    final bool isDarkMode = colors.brightness == Brightness.dark;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ✅ 1. FONDO CON GRADIENTE KITSU (diferente para light y dark)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      // Dark mode: mantiene el gradiente 
                      colors.surfaceContainerHighest, // Gris oscuro
                      colors.surfaceContainerLowest,  // Negro
                    ]
                  : [
                      // Light mode: balance entre sutil y notorio
                      colors.surfaceBright,           // Blanco brillante (#FDFDFD)
                      colors.surfaceContainerHigh,    // Gris suave (#EDEDED)
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            // 2. BORDE (se queda igual)
            border: Border.all(
              color: rarityColor.withOpacity(0.5),
              width: 1,
            ),
            // ✅ 3. ¡EL AURA! (BoxShadow mejorado)
            boxShadow: [
              BoxShadow(
                color: rarityColor.withOpacity(0.4), // Aura más intensa
                blurRadius: 15.0, // Más difuminada
                spreadRadius: 2.0,  // Un poco más grande
              )
            ],
          ),
          child: Row(
            children: [
              // --- El Icono del Logro ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  iconUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: colors.onSurface.withOpacity(0.1),
                      child: Icon(Icons.shield, color: rarityColor), // Icono de error con color de rareza
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // --- El Texto ---
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Logro Desbloqueado!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rarityColor, // Color Kitsu (de la rareza)
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreLogro,
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