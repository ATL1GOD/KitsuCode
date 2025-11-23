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
    final lockedTextColor = colors.onSurfaceVariant.withAlpha(179);

    // --- CAMBIOS DE DISEÑO PARA EL TEXTO ---
    // 1. Padding vertical mínimo pero seguro (1.5)
    final double verticalPadding = 1.5;

    // 2. Ajustamos la fuente para una buena legibilidad (10-11px)
    final double baseFontSize = isSmallScreen ? 10 : 11;

    // 3. Establecemos una altura mínima fija para el contenedor del texto (para 2 líneas + padding)
    // Asumimos que la altura de la línea de 10-11px es ~14-16px.
    // 2 líneas * 15px + 2 * 1.5px padding = ~33px de alto mínimo.
    final double minTextContainerHeight = isSmallScreen ? 30 : 35;

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
                ? effectColor.withAlpha(77)
                : colors.shadow.withOpacity(0.15),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. IMAGEN (Ocupa el espacio que queda libre)
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
                    : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                // LayoutBuilder asegura que OptimizedImage obtenga el tamaño exacto
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

          // 2. TEXTO INFERIOR (Anclado al fondo)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // Establecemos una altura mínima para evitar compresión vertical
              constraints: BoxConstraints(minHeight: minTextContainerHeight),
              alignment: Alignment
                  .center, // Centramos el texto verticalmente dentro de la nueva altura mínima
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding, // <-- Padding vertical mínimo
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                // ✅ Usar colores del tema
                color: isUnlocked
                    ? colors.surface.withAlpha(204)
                    : lockedBackgroundColor.withAlpha(230),
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
                  fontSize: baseFontSize, // <-- Tamaño ajustado
                  height:
                      1.2, // Añade un poco de espacio entre líneas (line-height)
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
