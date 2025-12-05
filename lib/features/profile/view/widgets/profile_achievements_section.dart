import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/widgets/optimized_glass_card.dart';
import 'achievement_card.dart';
import 'achievement_modal.dart';

class ProfileAchievementsSection extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;
  final bool enableGlassEffect;

  const ProfileAchievementsSection({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    this.enableGlassEffect = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(userAchievementsProvider(userId));
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // 3. Observar los datos del perfil que SÍ necesitamos
    final nombrePerfil = ref.watch(
      userProfileByIdProvider(
        userId,
      ).select((data) => data.value?.nombrePerfil),
    );

    // 4. Observar el objeto 'userProfile' completo.
    // Lo necesitamos para el modal.
    final userProfileData = ref.watch(userProfileByIdProvider(userId));
    final userProfile =
        userProfileData.value; // Puede ser null si está cargando

    Widget titleWidget(bool showButton) {
      // (Esta función interna no cambia)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: colors.secondary),
              const SizedBox(width: 8),
              Text(
                'Logros',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (showButton)
            TextButton(
              onPressed: () => context.push('/profile/$userId/achievements'),
              child: Text(
                'Ver todo',
                style: TextStyle(
                  color: colors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: OptimizedGlassCard(
        enableGlassEffect: enableGlassEffect,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              achievementsState.when(
                loading: () => titleWidget(false),
                error: (e, s) => titleWidget(false),
                data: (achievements) {
                  return titleWidget(achievements.isNotEmpty);
                },
              ),
              const SizedBox(height: 15),
              achievementsState.when(
                loading: () => _AchievementsLoadingShimmer(colors: colors),
                error: (error, stack) => const Center(
                  child: Text('No se pudieron cargar los logros'),
                ),
                data: (achievements) {
                  final obtained = achievements
                      .where((a) => a.obtenido)
                      .toList();

                  if (obtained.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/zorro_oops.png',
                            width: 60,
                            height: 60,
                            cacheWidth: 120,
                            cacheHeight: 120,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              // 5. Usar la variable 'nombrePerfil' observada
                              isCurrentUserProfile
                                  ? '¡Aún no has conseguido logros!'
                                  // Usamos '??' por si 'nombrePerfil' es null
                                  : '¡${nombrePerfil ?? '...'} aún no ha conseguido logros!',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 6. Manejar el caso donde los logros cargaron pero el perfil no
                  if (userProfile == null) {
                    return _AchievementsLoadingShimmer(colors: colors);
                  }

                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      cacheExtent: 200,
                      itemCount: obtained.length,
                      itemBuilder: (context, index) {
                        final achievement = obtained[index];
                        return GestureDetector(
                          onTap: () {
                            // 7. Usar el 'userProfile' observado
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
                                // 8. Usar el 'userProfile' observado
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

// _GlassCard removido - ahora usamos OptimizedGlassCard compartido

class _AchievementsLoadingShimmer extends StatelessWidget {
  final ColorScheme colors;
  const _AchievementsLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
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
      ),
    );
  }
}
