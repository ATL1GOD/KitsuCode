// lib/features/profile/view/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';

class ProfileHeader extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;

  // Control de efectos (por si el contenedor padre pausa pestañas/páginas)
  final bool isAppActive;
  final bool isTabVisible;

  const ProfileHeader({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    this.isAppActive = true,
    this.isTabVisible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileByIdProvider(userId));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return profileState.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(height: 365),
      error: (error, _) => SizedBox(
        height: 365,
        child: Center(child: Text('Error: $error')),
      ),
      data: (userProfile) {
        // Lista de avatares desde BD
        final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

        // Color dinámico (fallback al cálculo previo si aún no cargan avatares)
        final dynamicColor = (avatarsList.isNotEmpty)
            ? getAvatarColorById(userProfile.idAvatarSeleccionado, avatarsList)
            : AllStatsView.getHeaderColor(userProfile, colors);

        // Asset del avatar (fallback vacío → ícono de error)
        final avatarPath = (avatarsList.isNotEmpty)
            ? getAvatarAssetPathById(userProfile.idAvatarSeleccionado, avatarsList)
            : "";

        final Widget avatarImage = avatarPath.isEmpty
            ? const Icon(Icons.error, size: 40)
            : OptimizedImage(
                imagePath: avatarPath,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                enableCache: true,
              );

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Header ondulado con degradado del color del avatar
            ClipPath(
              clipper: const WaveClipper(),
              child: Container(
                height: 220,
                width: size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha(153), // ~0.6
                      dynamicColor.withAlpha(51),  // ~0.2
                    ],
                  ),
                ),
                // Partículas solo cuando realmente debe animar
                child: (isAppActive && isTabVisible)
                    ? RepaintBoundary(
                        child: ParticlesFly(
                          height: 220,
                          width: size.width,
                          connectDots: false,
                          numberOfParticles: 6, // 🔥 Reducido de 10 a 6 para mejor rendimiento
                          particleColor: Colors.white.withAlpha(102), // ~0.4 reducido
                          speedOfParticles: 0.4, // 🔥 Velocidad reducida para menor CPU usage
                          isRandomColor: false,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.only(top: 70.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: FadeIn(
                            duration: const Duration(milliseconds: 300),
                            delay: const Duration(milliseconds: 50),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: dynamicColor.withAlpha(128), // ~0.5
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: avatarImage,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isCurrentUserProfile)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: FadeIn(
                              duration: const Duration(milliseconds: 300),
                              delay: const Duration(milliseconds: 150),
                              child: Material(
                                elevation: 4,
                                color: colors.surface,
                                shape: const CircleBorder(),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: colors.secondary,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: colors.onSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => context.push('/edit-profile'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Nombre
                  FadeInUp(
                    from: 15,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      userProfile.nombrePerfil,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Username
                  FadeInUp(
                    from: 15,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      '@${userProfile.nombreUsuario}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withAlpha(179), // ~0.7
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Siguiendo / Seguidores
                  FadeInUp(
                    from: 15,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFollowStat(
                          context,
                          userProfile.siguiendoCount.toString(),
                          'Siguiendo',
                          userId,
                          'following',
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: colors.onSurface.withAlpha(51), // ~0.2
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        _buildFollowStat(
                          context,
                          userProfile.seguidoresCount.toString(),
                          'Seguidores',
                          userId,
                          'followers',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowStat(
    BuildContext context,
    String count,
    String label,
    String userId,
    String type,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () => context.push('/profile/$userId/follow/$type'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Column(
          children: [
            Text(
              count,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: onSurface.withAlpha(153), // ~0.6
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 50);
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint =
        Offset(size.width - (size.width / 4), size.height - 60);
    final secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
