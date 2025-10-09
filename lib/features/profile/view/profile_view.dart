import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart';
import 'package:animate_do/animate_do.dart';

class ProfileView extends ConsumerWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  // Función para obtener el color dinámico
  static Color getHeaderColor(UserProfileModel userProfile, ColorScheme colors) {
    final avatar = userProfile.avatarUrl.toLowerCase();
    if (avatar.contains('tiburon')) return const Color(0xFF0097A7);
    if (avatar.contains('zorro')) return const Color(0xFFE65100);
    if (avatar.contains('gato')) return const Color(0xFF7B1FA2);
    if (avatar.contains('león') || avatar.contains('leon')) return const Color(0xFFF57F17);
    if (avatar.contains('panda')) return const Color(0xFF2E7D32);
    return colors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;
    final targetUserId = userId ?? currentAuthUserId;
    final isCurrentUserProfile = targetUserId == currentAuthUserId;

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }
    
    final profileState = ref.watch(userProfileByIdProvider(targetUserId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (userProfile) {
          final dynamicColor = getHeaderColor(userProfile, colors);

          return Stack(
            children: [
              // Fondo con degradado dinámico (ocupa toda la pantalla)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withOpacity(0.4),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.6]
                  ),
                ),
              ),

              // Contenido principal
              Column(
                children: [
                  // --- PARTE FIJA (NO SCROLLEABLE) ---
                  SafeArea(
                    bottom: false, 
                    child: Column(
                      children: [
                        // Barra superior con botones
                        _TopBar(
                          isCurrentUserProfile: isCurrentUserProfile,
                          colors: colors,
                        ),
                        // Header con avatar y partículas
                        ProfileHeader(
                          userProfile: userProfile,
                          isCurrentUserProfile: isCurrentUserProfile,
                          dynamicColor: dynamicColor,
                        ),
                        // *** CAMBIO AQUÍ: BOTÓN DE SEGUIR AHORA ES FIJO ***
                        if (!isCurrentUserProfile)
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
                            child: SizedBox(
                              width: 300, // Ancho fijo para el botón
                              child: FollowButton(userId: targetUserId),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // --- PARTE CON SCROLL ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        // Ajustamos el padding superior dependiendo de si el botón de seguir es visible
                        padding: EdgeInsets.only(top: isCurrentUserProfile ? 20.0 : 0),
                        child: Column(
                          children: [
                            FadeInUp(
                              from: 20,
                              delay: const Duration(milliseconds: 600),
                              child: ProfileProgressSection(showViewAllButton: isCurrentUserProfile),
                            ),
                            FadeInUp(
                              from: 20,
                              delay: const Duration(milliseconds: 700),
                              child: const ProfileAchievementsSection(),
                            ),
                            const SizedBox(height: 70),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}


// Widget privado para la barra de botones superior (sin cambios)
class _TopBar extends StatelessWidget {
  final bool isCurrentUserProfile;
  final ColorScheme colors;

  const _TopBar({required this.isCurrentUserProfile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colors.onSurface),
            ),
          ),
          if (isCurrentUserProfile)
            Container(
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: colors.onSurface),
                onPressed: () { /* Navegar a settings */ },
              ),
            ),
        ],
      ),
    );
  }
}