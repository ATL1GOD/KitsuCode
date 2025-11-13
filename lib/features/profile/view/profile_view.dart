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
import 'package:animate_do/animate_do.dart';
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

    // Activar listeners de Realtime
    ref.watch(profileRealtimeProvider);
    ref.watch(achievementRealtimeProvider);
    ref.watch(followRealtimeProvider);

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }

    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // --- ¡OPTIMIZACIÓN! ---
    // ProfileView ya NO observa (ref.watch) los providers de datos.
    // Solo se encarga de armar el esqueleto.
    // Los hijos (ProfileHeader, ProfileProgressSection, etc.)
    // se encargarán de sus propios datos y estados de carga.

    return Scaffold(
      body: Stack(
        children: [
          // --- NUEVO WIDGET ---
          // Este widget SÍ observa el avatarId para el color de fondo.
          // Si el avatar cambia, SOLO esto se reconstruirá, no toda la vista.
          _ProfileBackground(
            userId: targetUserId,
            colors: colors,
          ),

          // Contenido principal (el esqueleto)
          Column(
            children: [
              // --- PARTE FIJA (NO SCROLLEABLE) ---
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 56), // Espacio para la barra de botones

                    // ProfileHeader ahora pide sus propios datos usando el userId
                    ProfileHeader(
                      userId: targetUserId,
                      isCurrentUserProfile: isCurrentUserProfile,
                      // ⛔ YA NO PASAMOS EL COLOR ⛔
                      // dynamicColor: colors.primary,
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

              // --- PARTE CON SCROLL ---
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.only(top: isCurrentUserProfile ? 20.0 : 0),
                    child: Stack(
                      children: [
                        // --- Animación de fondo ---
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
                        // --- Contenido del scroll ---
                        Column(
                          children: [
                            FadeInUp(
                              from: 30,
                              delay: const Duration(milliseconds: 300),
                              // ProfileProgressSection ya es un ConsumerWidget
                              // y pide sus propios datos. ¡Perfecto!
                              child: ProfileProgressSection(
                                userId: targetUserId,
                                showViewAllButton: isCurrentUserProfile,
                              ),
                            ),
                            FadeInUp(
                              from: 30,
                              delay: const Duration(milliseconds: 400),
                              // ProfileAchievementsSection ahora pide sus
                              // propios datos usando el userId
                              child: ProfileAchievementsSection(
                                userId: targetUserId,
                                isCurrentUserProfile: isCurrentUserProfile,
                              ),
                            ),
                            const SizedBox(height: 70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Barra de botones posicionada absolutamente (sin cambios)
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