import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class AchievementModal extends StatelessWidget {
  final UserAchievementModel achievement;
  final UserProfileModel profile;
  final bool isCurrentUser;

  const AchievementModal({
    super.key,
    required this.achievement,
    required this.profile,
    required this.isCurrentUser,
  });

  static Future<void> show(
    BuildContext context,
    UserAchievementModel achievement, {
    required UserProfileModel profile,
    required bool isCurrentUser,
  }) async {
    final theme = Theme.of(context);

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Theme(
            data: theme,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: _ModalContent(
                    achievement: achievement,
                    profile: profile,
                    isCurrentUser: isCurrentUser,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _ModalContent(
        achievement: achievement,
        profile: profile,
        isCurrentUser: isCurrentUser,
      ),
    );
  }
}

class _ModalContent extends StatelessWidget {
  final UserAchievementModel achievement;
  final UserProfileModel profile;
  final bool isCurrentUser;

  const _ModalContent({
    required this.achievement,
    required this.profile,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String raridad = achievement.raridad;
    final Color borderColor = getRarityColor(raridad);
    final String rarityText = getRarityText(raridad);
    final isUnlocked = achievement.obtenido;
    final lockedColor = colors.onSurfaceVariant.withValues(alpha: 0.5);

    Widget img = ColorFiltered(
      colorFilter: isUnlocked
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),

      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          width: 320,
          height: 210,
          padding: const EdgeInsets.all(0),

          child: OptimizedImage(
            imagePath: achievement.iconUrl,
            width: 320,
            height: 210,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    final animatedImg = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: img
          .animate()
          .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .then()
          .shake(duration: 600.ms, hz: 3, offset: const Offset(3, 3))
          .then()
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 250.ms,
            curve: Curves.easeOut,
          ),
    );

    final aura = isUnlocked
        ? Icon(
                Icons.auto_awesome,
                size: 120,
                color: borderColor.withValues(alpha: 0.35),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 800.ms,
              )
        : Icon(
                Icons.auto_awesome,
                size: 120,
                color: Colors.grey.shade600.withValues(alpha: 0.5),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 800.ms,
              );

    final String descriptionTitle;
    if (isUnlocked) {
      descriptionTitle = isCurrentUser
          ? "Obtuviste este logro por:"
          : "${profile.nombrePerfil} obtuvo este logro por:";
    } else {
      descriptionTitle = isCurrentUser
          ? "Para desbloquear este logro necesitas:"
          : "Para obtener este logro, se necesita:";
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: GestureDetector(
          onTap: () {},
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  aura,
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isUnlocked
                          ? colors.surface
                          : const Color(0xFFBDBDBD),
                      boxShadow: [
                        BoxShadow(
                          color: isUnlocked
                              ? borderColor.withValues(alpha: 0.7)
                              : Colors.grey.shade600.withValues(alpha: 0.6),
                          blurRadius: isUnlocked ? 30 : 20,
                          spreadRadius: isUnlocked ? 5 : 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                "Logro",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isUnlocked
                                          ? borderColor.withValues(alpha: 0.2)
                                          : Colors.grey.shade700,
                                      border: Border.all(
                                        color: isUnlocked
                                            ? borderColor
                                            : Colors.grey.shade500,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${achievement.id}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked
                                              ? borderColor
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? borderColor.withValues(alpha: 0.8)
                                          : Colors.grey.shade500,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rarityText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isUnlocked
                                            ? colors.onPrimary
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      isUnlocked ? "¡OBTENIDO!" : "BLOQUEADO",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? const Color(0xFF00FF00)
                                            : lockedColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isUnlocked
                                    ? borderColor
                                    : Colors.grey.shade600,
                                width: 4,
                              ),
                              color: isUnlocked
                                  ? colors.surface
                                  : Colors.grey.shade800,
                              boxShadow: !isUnlocked
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    animatedImg,
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Text(
                                        achievement.nombre.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isUnlocked
                                              ? colors.onSurface
                                              : Colors.grey.shade400,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Icon(
                                      isUnlocked
                                          ? Icons.star
                                          : Icons.lock_outline,
                                      color: isUnlocked
                                          ? borderColor
                                          : Colors.grey.shade500,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            descriptionTitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isUnlocked
                                                  ? colors.onSurfaceVariant
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            achievement.descripcion,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isUnlocked
                                                  ? colors.onSurfaceVariant
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          size: 60,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Cerrar",
                              style: TextStyle(color: colors.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
