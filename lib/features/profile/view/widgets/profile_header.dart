import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel userProfile;
  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget avatarImage;
    if (userProfile.avatarUrl.startsWith('http')) {
      avatarImage = Image.network(userProfile.avatarUrl, fit: BoxFit.cover);
    } else {
      avatarImage = Image.asset(userProfile.avatarUrl, fit: BoxFit.cover);
    }

    return Column(
      children: [
        //const SizedBox(height: 10), // Espacio superior opcional creo jaja
        Stack(
          clipBehavior: Clip.none, // Permite que el botón de editar se salga
          alignment: Alignment.center,
          children: [
            // --- AVATAR CON SOMBRA ---
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: colors.secondary.withOpacity(0.6), // Color del tema
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.secondary, // Color del tema
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27.0),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: avatarImage,
                ),
              ),
            ),
            // BOTÓN DE EDITAR FLOTANTE
            Positioned(
              bottom: -10,
              right: -10,
              child: Material(
                color: colors.surface,
                elevation: 4,
                shadowColor: colors.shadow.withOpacity(0.3),
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primary,
                  child: IconButton(
                    icon: Icon(Icons.edit, color: colors.onPrimary, size: 20),
                    onPressed: () => context.push('/edit-profile', extra: userProfile),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- NOMBRES DE PERFIL Y USUARIO ---
        Text(
          userProfile.nombrePerfil,
          style: textTheme.headlineSmall,
        ),
        Text(
          '@${userProfile.nombreUsuario}',
          style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant.withOpacity(0.8)),
        ),
        const SizedBox(height: 20),

        // --- CONTADORES DE SEGUIDORES ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFollowStat(context, userProfile.siguiendoCount.toString(), 'Siguiendo'),
            Container(
              height: 30,
              width: 1,
              color: colors.onSurfaceVariant.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            _buildFollowStat(context, userProfile.seguidoresCount.toString(), 'Seguidores'),
          ],
        ),
        //const SizedBox(height: 15),
      ],
    );
  }

  // Widget auxiliar para los contadores de seguidores
  Widget _buildFollowStat(BuildContext context, String count, String label) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(count, style: textTheme.titleLarge),
        Text(label, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7))),
      ],
    );
  }
} 