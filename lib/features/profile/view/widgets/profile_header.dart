import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel userProfile;
  final bool isCurrentUserProfile;
  final Color dynamicColor;

  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.isCurrentUserProfile,
    required this.dynamicColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    Widget avatarImage;
    if (userProfile.avatarUrl.startsWith('http')) {
      avatarImage = Image.network(userProfile.avatarUrl, fit: BoxFit.cover);
    } else {
      avatarImage = Image.asset(userProfile.avatarUrl, fit: BoxFit.cover);
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 1. EL FONDO CURVO CON LAS PARTÍCULAS
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: 220, // Altura del fondo
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
            child: ParticlesFly(
              height: 220,
              width: size.width,
              connectDots: false,
              numberOfParticles: 20,
              particleColor: Colors.white.withOpacity(0.5),
              speedOfParticles: 0.5,
              isRandomColor: false,
            ),
          ),
        ),

        // 2. TU CÓDIGO ORIGINAL (Avatar y textos) AHORA MÁS ARRIBA
        Padding(
          padding: const EdgeInsets.only(top: 70.0), // *** CAMBIO AQUÍ: SUBIMOS EL CONTENIDO ***
          child: Column(
            children: [
              // CONTENEDOR DEL AVATAR Y BOTÓN
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: FadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
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
                          delay: const Duration(milliseconds: 600),
                          child: Material(
                            elevation: 4,
                            color: colors.surface,
                            shape: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: colors.secondary,
                              child: IconButton(
                                icon: Icon(Icons.edit, color: colors.onSecondary, size: 20),
                                onPressed: () => context.push('/edit-profile'),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // TEXTOS Y STATS
              const SizedBox(height: 15),
              FadeInUp(
                from: 20,
                delay: const Duration(milliseconds: 300),
                child: Text(
                  userProfile.nombrePerfil,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FadeInUp(
                from: 20,
                delay: const Duration(milliseconds: 400),
                child: Text(
                  '@${userProfile.nombreUsuario}',
                  style: textTheme.bodyLarge?.copyWith(color: colors.onSurface.withOpacity(0.7)),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                from: 20,
                delay: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFollowStat(context, userProfile.siguiendoCount.toString(), 'Siguiendo'),
                    Container(
                      height: 30,
                      width: 1,
                      color: colors.onSurface.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    _buildFollowStat(context, userProfile.seguidoresCount.toString(), 'Seguidores'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowStat(BuildContext context, String count, String label) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(count, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}

// Clipper para la forma de ola (sin cambios)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
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