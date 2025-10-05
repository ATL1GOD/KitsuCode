import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

class ProfileView extends ConsumerWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;
    final targetUserId = userId ?? currentAuthUserId;
    final isCurrentUserProfile = targetUserId == currentAuthUserId;

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }
    
    final profileState = ref.watch(userProfileByIdProvider(targetUserId));

    return Scaffold(
      body: Stack(
        children: [
          const LoginBackground(child: SizedBox.shrink()),
          profileState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
            data: (userProfile) {
              return SafeArea(
                child: Column(
                  children: [
                    // --- ENCABEZADO FIJO ---
                    _FixedHeader(
                      userProfile: userProfile,
                      isCurrentUserProfile: isCurrentUserProfile,
                    ),

                    // --- CONTENIDO CON SCROLL ---
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // ¡CORRECCIÓN! Movemos el botón de seguir a la zona de scroll
                            if (!isCurrentUserProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                                child: FollowButton(userId: targetUserId),
                              ),
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: ProfileProgressSection(showViewAllButton: isCurrentUserProfile),
                            ),
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: const ProfileAchievementsSection(),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// WIDGET PRIVADO PARA EL ENCABEZADO FIJO
class _FixedHeader extends StatelessWidget {
  final UserProfileModel userProfile;
  final bool isCurrentUserProfile;

  const _FixedHeader({
    required this.userProfile,
    required this.isCurrentUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Barra de navegación superior
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
                ),
              ),
              if (isCurrentUserProfile)
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: colors.onSurface),
                  onPressed: () { /* Navegar a settings */ },
                ),
            ],
          ),
        ),
        // Contenido del perfil
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: ProfileHeader(
            userProfile: userProfile,
            // ¡CORRECCIÓN! Le pasamos el booleano al Header
            isCurrentUserProfile: isCurrentUserProfile,
          ),
        ),
      ],
    );
  }
}


class _ProfileLoadingShimmer extends StatelessWidget {
  const _ProfileLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[200]!,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 380,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}