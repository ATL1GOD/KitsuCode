// lib/features/profile/view/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';

class ProfileHeader extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;
  // --- 🔥 1. AÑADIR NUEVAS PROPIEDADES ---
  final bool isAppActive;
  final bool isTabVisible;

  const ProfileHeader({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    // --- 🔥 2. AÑADIR AL CONSTRUCTOR (requeridas) ---
    this.isAppActive = true, // Valor por defecto por si se usa en otro lado
    this.isTabVisible = true, // Valor por defecto
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileByIdProvider(userId));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return profileState.when(
      skipLoadingOnRefresh: true,
      loading: () {
        return const SizedBox(height: 365); // Placeholder
      },
      error: (error, stack) {
        return SizedBox(
          height: 365,
          child: Center(child: Text('Error: $error')),
        );
      },
      data: (userProfile) {
        final dynamicColor =
            getAvatarColorById(userProfile.idAvatarSeleccionado);
        final avatarAssetPath =
            getAvatarAssetPathById(userProfile.idAvatarSeleccionado);
        Widget avatarImage = Image.asset(avatarAssetPath, fit: BoxFit.cover);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 220,
                width: size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withOpacity(0.6),
                      dynamicColor.withOpacity(0.2),
                    ],
                  ),
                ),
                // --- 🔥 3. APLICAR LÓGICA DE VISIBILIDAD ---
                child: (isAppActive && isTabVisible) // <-- ¡LA CONDICIÓN!
                    ? ParticlesFly(
                        height: 220,
                        width: size.width,
                        connectDots: false,
                        numberOfParticles: 20,
                        particleColor: Colors.white.withOpacity(0.5),
                        speedOfParticles: 0.5,
                        isRandomColor: false,
                      )
                    : const SizedBox.shrink(), // <-- Si no, no renderizar nada
              ),
            ),
            // ... (El resto de tu widget no cambia) ...
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
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: dynamicColor.withOpacity(0.5),
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
                                    icon: Icon(Icons.edit,
                                        color: colors.onSecondary, size: 20),
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
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FadeInUp(
                    from: 15,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      '@${userProfile.nombreUsuario}',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colors.onSurface.withOpacity(0.7)),
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
                          color: colors.onSurface.withOpacity(0.2),
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

  // (Método _buildFollowStat sin cambios)
  Widget _buildFollowStat(BuildContext context, String count, String label,
      String userId, String type) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        context.push('/profile/$userId/follow/$type');
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Column(
          children: [
            Text(count,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(label,
                style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

// (Clipper sin cambios)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint =
        Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}