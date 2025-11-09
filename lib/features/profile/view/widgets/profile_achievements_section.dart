// lib/features/profile/view/widgets/profile_achievements_section.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:animate_do/animate_do.dart'; // Import no usado
import 'package:go_router/go_router.dart';

import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
// import 'package:kitsucode/features/profile/model/user_achievement_model.dart'; // Import no usado

import 'achievement_card.dart';
import 'achievement_modal.dart';

class ProfileAchievementsSection extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;
  final UserProfileModel userProfile;

  const ProfileAchievementsSection({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(userAchievementsProvider(userId));
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    Widget titleWidget(bool showButton) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: colors.secondary),
              const SizedBox(width: 8),
              Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (showButton)
            TextButton(
              onPressed: () => context.push('/profile/$userId/achievements'),
              child: Text('Ver todo', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              achievementsState.when(
                loading: () => titleWidget(false),
                error: (e, s) => titleWidget(false),
                data: (achievements) {
                  // Mostrar el botón siempre que haya logros (obtenidos o no)
                  return titleWidget(achievements.isNotEmpty);
                },
              ),

              const SizedBox(height: 15),

              achievementsState.when(
                loading: () => _AchievementsLoadingShimmer(colors: colors),
                error: (error, stack) => const Center(child: Text('No se pudieron cargar los logros')),
                data: (achievements) {
                  final obtained = achievements.where((a) => a.obtenido).toList();

                  if (obtained.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/zorro_oops.png', width: 60, height: 60),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              isCurrentUserProfile
                                  ? '¡Aún no has conseguido logros!'
                                  : '¡${userProfile.nombrePerfil} aún no ha conseguido logros!',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: obtained.length,
                      itemBuilder: (context, index) {
                        final achievement = obtained[index];

                        return GestureDetector(
                          onTap: () {
                            // ✅ 1. ¡CORRECCIÓN AQUÍ!
                            AchievementModal.show(
                              context, 
                              achievement,
                              profile: userProfile,
                              isCurrentUser: isCurrentUserProfile,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: SizedBox(
                              width: 90,
                              child: AchievementCard(
                                achievement: achievement,
                                colors: colors,
                                isCompactView: true,
                                // ✅ 2. ¡CORRECCIÓN AQUÍ!
                                profile: userProfile,
                                isCurrentUser: isCurrentUserProfile,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el tema y el brillo
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // 2. Definimos los colores adaptativos
    final Color cardColor;
    final Color borderColor;

    if (isDarkMode) {
      // --- MODO OSCURO ---
      // Glass effect más sutil con gris oscuro
      cardColor = colors.surfaceContainerHighest.withOpacity(0.6); 
      borderColor = colors.outline.withOpacity(0.3);
    } else {
      // --- MODO CLARO ---
      // Glass effect más transparente para ver las partículas
      cardColor = Colors.white.withOpacity(0.2); 
      borderColor = colors.outline.withOpacity(0.2);
    }

    // 3. Construimos el widget
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Mantenemos el blur
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,     // <-- Color adaptativo
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor) // <-- Borde adaptativo
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AchievementsLoadingShimmer extends StatelessWidget {
  final ColorScheme colors;
  const _AchievementsLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: SizedBox(
        height: 120, // Ajustado a la altura de la tarjeta
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}