import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importamos el modelo de perfil de usuario
import 'package:kitsucode/features/profile/model/user_profile_model.dart'; 
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:shimmer/shimmer.dart';

String _getAchievementIconPath(String achievementName) {
  switch (achievementName.toLowerCase()) {
    case 'primer reto':
      return 'assets/images/logro_1.png';
    case 'racha de 5 días':
      return 'assets/images/logro_racha.png';
    case 'experto en java':
      return 'assets/images/logro_java.png';
    default:
      return 'assets/images/logro_default.png';
  }
}

class ProfileAchievementsSection extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;
  // --- CAMBIO 1: AÑADIMOS EL PERFIL DEL USUARIO ---
  final UserProfileModel userProfile;

  const ProfileAchievementsSection({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    // --- CAMBIO 2: LO HACEMOS REQUERIDO EN EL CONSTRUCTOR ---
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(userAchievementsProvider(userId));
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              achievementsState.when(
                loading: () => Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                error: (e, s) => Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                data: (achievements) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (achievements.isNotEmpty)
                        TextButton(
                          onPressed: () {},
                          child: Text('Ver todo', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
              achievementsState.when(
                loading: () => const _AchievementsLoadingShimmer(),
                error: (error, stack) => const Center(child: Text('No se pudieron cargar los logros')),
                data: (achievements) {
                  if (achievements.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/zorro_oops.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              // --- CAMBIO 3: USAMOS EL NOMBRE DEL PERFIL ---
                              isCurrentUserProfile
                                  ? '¡Aún no has conseguido logros!'
                                  // Usamos el `nombrePerfil` del objeto `userProfile`
                                  : '¡${userProfile.nombrePerfil} aún no ha conseguido logros!',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = achievements[index];
                        final imagePath = _getAchievementIconPath(achievement.nombre);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Tooltip(
                            message: '${achievement.nombre}\n${achievement.descripcion}',
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: colors.primaryContainer.withOpacity(0.7),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(imagePath),
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

// ... El resto del archivo no cambia
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5))
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AchievementsLoadingShimmer extends StatelessWidget {
  const _AchievementsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[200]!,
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: CircleAvatar(radius: 40, backgroundColor: Colors.white),
          ),
        ),
      ),
    );
  }
}