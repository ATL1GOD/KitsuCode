// lib/features/profile/view/widgets/achievement_modal.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart'; 
import 'package:flutter_animate/flutter_animate.dart';

// Color para el estado/rareza
const Color _legendaryColor = Color(0xFF00FF00); // Verde neón

class AchievementModal extends StatelessWidget {
  final UserAchievementModel achievement;

  const AchievementModal({super.key, required this.achievement});

  // --- LÓGICA DE COLOR TEMPORAL (BASADA EN ID) ---
  Color _getBorderColor(int achievementId, ColorScheme colors) {
    switch (achievementId % 3) {
      case 0: return colors.secondary; 
      case 1: return colors.primary; 
      case 2: return const Color(0xFF00FF00); 
      default: return colors.outline;
    }
  }

  // --- TEXTO DE RAREZA TEMPORAL (BASADA EN ID) ---
  String _getRarityText(int achievementId) {
    switch (achievementId % 3) {
      case 0: return 'ÉPICO';
      case 1: return 'COMÚN';
      case 2: return 'LEGENDARIO';
      default: return 'DESCONOCIDO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = _getBorderColor(achievement.id, colors);
    final rarityText = _getRarityText(achievement.id);

    final isUnlocked = achievement.obtenido;
    final lockedColor = colors.onSurfaceVariant.withOpacity(0.5);

    // Filtro de color solo para el arte/imagen
    final imageColorFilter = isUnlocked 
      ? null 
      : const ColorFilter.mode(Colors.grey, BlendMode.saturation);
      
    // Definición de la sombra: Colorida solo si está desbloqueado
    final List<BoxShadow> boxShadowList = isUnlocked 
      ? [
          BoxShadow(
            color: borderColor.withOpacity(0.8),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ]
      : [
          // Sombra sutil y neutra para el estado bloqueado
          BoxShadow(
            color: colors.shadow.withOpacity(0.15), 
            blurRadius: 10, // ¡CORRECCIÓN A blurRadius!
            spreadRadius: 2,
          ),
        ];

    return Dialog(
      backgroundColor: Colors.transparent, 
      child: Center(
        child: Container( 
          width: 300, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.surface, 
            boxShadow: boxShadowList, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Cabecera (Logro, Estado, RAREZA)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Logro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurface)
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID: ${achievement.id}', 
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isUnlocked ? colors.onSurfaceVariant : lockedColor)
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUnlocked ? borderColor.withOpacity(0.8) : lockedColor, 
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rarityText, 
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? colors.onPrimary : colors.surface,
                                ),
                          ),
                        ),
                        Text(
                          isUnlocked ? '¡OBTENIDO!' : 'BLOQUEADO', 
                          style: TextStyle(
                            color: isUnlocked ? const Color(0xFF00FF00) : lockedColor, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Tarjeta Principal 
              Container(
                width: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isUnlocked ? borderColor : lockedColor,
                    width: 4,
                  ),
                  color: colors.surface,
                ),
                child: Column(
                  children: [
                    // Imagen/Arte: Aplicamos el filtro SÓLO a la imagen
                    ColorFiltered(
                      colorFilter: imageColorFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Image.asset(
                          achievement.iconUrl, 
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // Nombre y descripción (Aseguramos color condicional)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
                      child: Text(
                        achievement.nombre.toUpperCase(), 
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isUnlocked ? colors.onSurface : lockedColor,
                            ),
                      ),
                    ),
                    
                    Icon(
                      isUnlocked ? Icons.star : Icons.lock_outline,
                      color: isUnlocked ? borderColor : lockedColor,
                      size: 24,
                    ),
                    
                    const SizedBox(height: 10),

                    // Descripción / Requisito
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Column(
                          children: [
                              Text(
                                  isUnlocked ? 'Obtuviste este logro por:' : 'Para obtener este logro, necesitas:',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: isUnlocked ? colors.onSurfaceVariant : lockedColor,
                                      fontWeight: FontWeight.bold,
                                  ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  achievement.descripcion, 
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isUnlocked ? colors.onSurfaceVariant : lockedColor,
                                  ),
                              ),
                          ]
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Botón de Cerrar
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    foregroundColor: colors.onPrimary, 
                  ),
                  child: Text('Cerrar', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}