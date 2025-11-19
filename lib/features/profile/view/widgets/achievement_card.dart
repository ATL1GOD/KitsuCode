// lib/features/profile/view/widgets/achievement_card.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
// helpers
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart';
// ✅ IMPORTANTE: Importar el optimizador
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class AchievementCard extends StatelessWidget {
  final UserAchievementModel achievement;
  final ColorScheme colors;
  final bool isCompactView;
  final bool isClickable;

  // Nuevos parámetros para el perfil y si es el usuario actual
  final UserProfileModel profile;
  final bool isCurrentUser;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.colors,
    this.isCompactView = false,
    this.isClickable = true,
    required this.profile, // perfil del usuario
    required this.isCurrentUser, // si es el usuario actual o no
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.obtenido;

    // ✅ Helper de color
    final effectColor = getRarityColor(achievement.raridad);

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // ✅ Usar colores del tema
    final double borderWidth = isUnlocked ? 3 : 1;
    final borderColor = isUnlocked ? effectColor : colors.outline;
    final lockedBackgroundColor = colors.surfaceContainerHigh;
    final lockedTextColor = colors.onSurfaceVariant.withOpacity(0.7);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        // ✅ Usar colores del tema
        color: isUnlocked ? colors.surface : lockedBackgroundColor,
        boxShadow: [
          BoxShadow(
            // ✅ Sombra según estado usando colores del tema
            color: isUnlocked
                ? effectColor.withOpacity(0.3)
                : colors.shadow.withOpacity(0.15),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColorFiltered(
                colorFilter: isUnlocked
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      )
                    : const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                // ✅ CAMBIO AQUÍ: Usamos LayoutBuilder + OptimizedImage
                // LayoutBuilder nos da el tamaño disponible para pedir la imagen exacta
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return OptimizedImage(
                      imagePath: achievement.iconUrl, // Ruta en Supabase
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.cover,
                      enableCache: true,
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 4.0 : 6.0,
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                // ✅ Usar colores del tema
                color: isUnlocked
                    ? colors.surface.withOpacity(0.8)
                    : lockedBackgroundColor.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Text(
                achievement.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 9 : 10,
                  // ✅ Texto con color del tema
                  color: isUnlocked ? colors.onSurface : lockedTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // ✅ Lógica de click para abrir el modal
    if (isClickable) {
      return GestureDetector(
        onTap: () => AchievementModal.show(
          context,
          achievement,
          profile: profile,
          isCurrentUser: isCurrentUser,
        ),
        child: cardContent,
      );
    }
    // Si no es clickeable, solo retorna el contenido
    return cardContent;
  }
}