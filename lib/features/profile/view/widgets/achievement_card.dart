import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

import 'package:kitsucode/features/profile/utils/achievement_helpers.dart';

import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class AchievementCard extends StatelessWidget {
  final UserAchievementModel achievement;
  final ColorScheme colors;
  final bool isCompactView;
  final bool isClickable;

  final UserProfileModel profile;
  final bool isCurrentUser;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.colors,
    this.isCompactView = false,
    this.isClickable = true,
    required this.profile,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.obtenido;

    final effectColor = getRarityColor(achievement.raridad);

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    final double borderWidth = isUnlocked ? 3 : 1;
    final borderColor = isUnlocked ? effectColor : colors.outline;
    final lockedBackgroundColor = colors.surfaceContainerHigh;
    final lockedTextColor = colors.onSurfaceVariant.withAlpha(179);

    final double verticalPadding = 1.5;

    final double baseFontSize = isSmallScreen ? 10 : 11;

    final double minTextContainerHeight = isSmallScreen ? 30 : 35;

    Widget cardContent = RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),

          color: isUnlocked ? colors.surface : lockedBackgroundColor,
          boxShadow: [
            BoxShadow(
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
                          Colors.grey,
                          BlendMode.saturation,
                        ),

                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return OptimizedImage(
                        imagePath: achievement.iconUrl,
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
                constraints: BoxConstraints(minHeight: minTextContainerHeight),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
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
                    fontSize: baseFontSize,
                    height: 1.2,

                    color: isUnlocked ? colors.onSurface : lockedTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

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

    return cardContent;
  }
}
