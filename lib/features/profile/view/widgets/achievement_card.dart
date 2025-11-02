// lib/features/profile/view/widgets/achievement_card.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart'; 
import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart';


class AchievementCard extends StatelessWidget {
    final UserAchievementModel achievement;
    final ColorScheme colors;
    final bool isCompactView;

    const AchievementCard({
        super.key,
        required this.achievement,
        required this.colors,
        this.isCompactView = false,
    });

    // --- LÓGICA DE COLOR TEMPORAL (BASADA EN ID DE LOGRO) ---
    Color _getBorderColor(int achievementId, ColorScheme colors) {
        switch (achievementId % 3) {
            case 0: return colors.secondary;
            case 1: return colors.primary;
            case 2: return const Color(0xFF00FF00); 
            default: return colors.outline;
        }
    }

    @override
    Widget build(BuildContext context) {
        // Colores y propiedades de la tarjeta
        final neutralBorderColor = colors.outlineVariant;
        final effectColor = _getBorderColor(achievement.id, colors); 
        
        final isUnlocked = achievement.obtenido;
        final opacity = isUnlocked ? 1.0 : 0.4;
        
        final imagePadding = 4.0;
        final borderRadius = BorderRadius.circular(12);

        final double radiusValue = borderRadius.topLeft.x; 

        return Opacity(
            opacity: opacity,
            child: GestureDetector(
                onTap: () {
                    // LÓGICA CLAVE: Barrera condicional
                    final modalBarrierColor = achievement.obtenido 
                        ? Colors.black54 // Oscurece el fondo (para desbloqueados)
                        : Colors.transparent; // Mantiene el fondo visible (para bloqueados)
                        
                    showDialog(
                        context: context,
                        barrierColor: modalBarrierColor, 
                        builder: (ctx) => AchievementModal(achievement: achievement),
                    );
                },
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        border: Border.all(
                            color: isCompactView ? neutralBorderColor : effectColor, 
                            width: isCompactView ? 1.0 : 3.0,
                        ),
                        color: colors.surface, 
                        boxShadow: [
                            BoxShadow(
                                color: effectColor.withOpacity(isCompactView ? 0.1 : 0.3),
                                blurRadius: 3,
                                spreadRadius: 0,
                            ),
                        ],
                    ),
                    // Usamos Stack para el diseño superpuesto
                    child: Stack(
                        fit: StackFit.expand,
                        children: [
                            // 1. Imagen del Logro (Casi toda la tarjeta)
                            Padding(
                                padding: EdgeInsets.all(imagePadding),
                                child: ColorFiltered(
                                    colorFilter: isUnlocked 
                                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                        : const ColorFilter.mode(Colors.grey, BlendMode.saturation), 
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(radiusValue - imagePadding), 
                                        child: Image.asset(
                                            achievement.iconUrl, 
                                            fit: BoxFit.cover,
                                        ),
                                    ),
                                ),
                            ),
                            
                            // 2. Fondo para el Nombre del Logro (Mejora la legibilidad)
                            Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                    decoration: BoxDecoration(
                                        color: colors.surface.withOpacity(0.8), 
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(radiusValue - imagePadding),
                                            bottomRight: Radius.circular(radiusValue - imagePadding),
                                        ),
                                    ),
                                    child: Text(
                                        achievement.nombre, 
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10, 
                                                color: colors.onSurface,
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
}