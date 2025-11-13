import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart';
import 'package:animate_do/animate_do.dart'; // <--- ¡ANIMACIÓN RE-IMPORTADA!
import 'package:lottie/lottie.dart';

class ProfileView extends ConsumerWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  // Este método estático se queda igual
  static Color getHeaderColor(UserProfileModel userProfile, ColorScheme colors) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;
    final targetUserId = userId ?? currentAuthUserId;
    final isCurrentUserProfile = targetUserId == currentAuthUserId;

    // Activar listeners de Realtime (esto está perfecto)
    ref.watch(profileRealtimeProvider);
    ref.watch(achievementRealtimeProvider);
    ref.watch(followRealtimeProvider);

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }

    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo dinámico (esto está perfecto)
          _ProfileBackground(
            userId: targetUserId,
            colors: colors,
          ),

          // Contenido principal
          Column(
            children: [
              // --- PARTE FIJA (NO SCROLLEABLE) ---
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 56), // Espacio para la barra de botones

                    // ProfileHeader (perfecto, pide sus propios datos)
                    ProfileHeader(
                      userId: targetUserId,
                      isCurrentUserProfile: isCurrentUserProfile,
                    ),

                    if (!isCurrentUserProfile)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 30.0, bottom: 20.0),
                        child: SizedBox(
                          width: 300,
                          child: FollowButton(userId: targetUserId),
                        ),
                      ),
                  ],
                ),
              ),

              // --- PARTE CON SCROLL (REFACTORIZADA) ---
              Expanded(
                child: Stack(
                  children: [
                    // --- 1. FONDO LOTTIE (FIJO) ---
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          isDarkMode
                              ? colors.secondaryFixedDim.withOpacity(0.3)
                              : colors.secondary.withOpacity(0.4),
                          BlendMode.srcIn,
                        ),
                        child: Lottie.asset(
                          'assets/animations/particles.json',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // --- 2. LISTVIEW (LAZY LOADING) ---
                    ListView(
                      // Añadimos padding aquí para el contenido
                      padding: EdgeInsets.only(
                        top: isCurrentUserProfile ? 20.0 : 0,
                        bottom: 70.0, // Espacio para el final del scroll
                      ),
                      children: [
                        // --- ¡ANIMACIÓN DEVUELTA! ---
                        FadeInUp(
                          from: 30,
                          delay: const Duration(milliseconds: 300),
                          child: ProfileProgressSection(
                            userId: targetUserId,
                            showViewAllButton: isCurrentUserProfile,
                          ),
                        ),
                        
                        // --- ¡ANIMACIÓN DEVUELTA! ---
                        FadeInUp(
                          from: 30,
                          delay: const Duration(milliseconds: 400),
                          child: ProfileAchievementsSection(
                            userId: targetUserId,
                            isCurrentUserProfile: isCurrentUserProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Barra de botones posicionada (perfecto)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _TopBar(
                isCurrentUserProfile: isCurrentUserProfile,
                colors: colors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET NUEVO Y PRIVADO ---
// Este widget solo se encarga de construir el fondo dinámico
// (Sin cambios, esto está perfecto)
class _ProfileBackground extends ConsumerWidget {
  final String userId;
  final ColorScheme colors;

  const _ProfileBackground({required this.userId, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos SÓLO el id del avatar
    final avatarId = ref.watch(userProfileByIdProvider(userId)
        .select((data) => data.value?.idAvatarSeleccionado));

    // Si está cargando, usamos un color por defecto
    final dynamicColor = avatarId != null
        ? getAvatarColorById(avatarId)
        : colors.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dynamicColor.withAlpha((255 * 0.4).round()),
              colors.surfaceContainerLowest,
            ],
            stops: const [0.0, 0.6]),
      ),
    );
  }
}

// Widget _TopBar con los botones de navegación (Sin cambios)
class _TopBar extends StatelessWidget {
  final bool isCurrentUserProfile;
  final ColorScheme colors;

  const _TopBar({required this.isCurrentUserProfile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colors.surface.withAlpha((255 * 0.3).round()),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
            ),
          ),
          if (isCurrentUserProfile)
            InkWell(
              onTap: () {
                context.push('/settings');
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colors.surface.withAlpha((255 * 0.3).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings_outlined, color: colors.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}