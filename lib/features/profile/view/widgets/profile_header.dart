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
      error: (error, _) =>
          SizedBox(height: 365, child: Center(child: Text('Error: $error'))),
      data: (userProfile) {
        final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

        final dynamicColor = (avatarsList.isNotEmpty)
            ? getAvatarColorById(userProfile.idAvatarSeleccionado, avatarsList)
            : AllStatsView.getHeaderColor(userProfile, colors);

        final avatarPath = (avatarsList.isNotEmpty)
            ? getAvatarAssetPathById(
                userProfile.idAvatarSeleccionado,
                avatarsList,
              )
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
                      dynamicColor.withAlpha(153),
                      dynamicColor.withAlpha(51),
                    ],
                  ),
                ),

                child: (isAppActive && isTabVisible)
                    ? RepaintBoundary(
                        child: ParticlesFly(
                          height: 220,
                          width: size.width,
                          connectDots: false,
                          numberOfParticles: 6,
                          particleColor: Colors.white.withAlpha(102),
                          speedOfParticles: 0.4,
                          isRandomColor: false,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 70.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
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

                                gradient: LinearGradient(
                                  colors: [dynamicColor, colors.primary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: dynamicColor.withAlpha(179),
                                    blurRadius: 25,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),

                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.transparent,
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
                                    onPressed: () =>
                                        context.push('/edit-profile'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

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

                  FadeInUp(
                    from: 15,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      '@${userProfile.nombreUsuario}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withAlpha(179),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                          color: colors.onSurface.withAlpha(51),
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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 60,
    );
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
