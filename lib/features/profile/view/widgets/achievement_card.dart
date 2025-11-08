// lib/features/profile/view/widgets/achievement_card.dart
// (ESTE CÓDIGO NO TIENE EL IF/ELSE Y USA SIEMPRE EL MODAL BUENO)

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart'; 
import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart'; // Importa el modal BUENO

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
    final isUnlocked = achievement.obtenido;
    final effectColor = _getBorderColor(achievement.id, colors);

    final double opacity = isUnlocked ? 1.0 : 0.4;
    final double borderWidth = isUnlocked ? 3 : 1;
    final borderColor = isUnlocked ? effectColor : colors.outlineVariant;

    return GestureDetector(
      // 💡 ¡CORRECCIÓN! Solo permite el onTap si está desbloqueado.
      // Si está bloqueado, el clic lo manejará el GestureDetector de la cuadrícula superior.
      onTap: isUnlocked ? () { 
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.6), 
          // ¡SIEMPRE LLAMA AL MODAL BUENO!
          builder: (ctx) => AchievementModal(achievement: achievement),
        );
      } : null,
      
      child: Opacity(
        opacity: opacity,
        child: Container(
          // ... (Todo tu código de Container, Stack, etc. va aquí)
          // ... (El que ya tenías está perfecto)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: effectColor.withOpacity(0.3),
                blurRadius: 3,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.mode(Colors.grey, BlendMode.saturation), 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      achievement.iconUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Text(
                    achievement.nombre,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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