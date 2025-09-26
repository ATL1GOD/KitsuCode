import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const LoginBackground(child: SizedBox.shrink()),

          profileState.when(
            loading: () => const _ProfileLoadingShimmer(),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
            data: (userProfile) {
              return CustomScrollView(
                slivers: [
                  // --- SLIVERAPPBAR SIMPLIFICADO ---
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 390.0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () => context.pop(), // La acción para regresar
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: colors.onSurface),
                        onPressed: () { /* TODO: Navegar a settings */ },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      
                      background: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          // El ProfileHeader es el único responsable de la info del encabezado
                          child: ProfileHeader(userProfile: userProfile),
                        ),
                      ),
                    ),
                  ),

                  // --- CUERPO DEL PERFIL ---
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: const ProfileProgressSection(),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: const ProfileAchievementsSection(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


// --- WIDGET DE SHIMMER PARA EL ESTADO DE CARGA ---
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
            height: 380, // Simula el alto del SliverAppBar
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