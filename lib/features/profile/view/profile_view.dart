// lib/features/profile/view/profile_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart'; // Importamos el provider
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_info_card.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart'; 
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';


class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. "Observamos" el estado de nuestro provider de perfil
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Capa 1: El fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDA85E), Color(0xFFF1E1D0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Capa 2: Las estrellas (iconos posicionados)
          const _Sparkles(),

          // Capa 3: El contenido principal de la pantalla
          profileState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error al cargar el perfil: $error')),
            data: (userProfile) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4F4F4F)),
                      onPressed: () {},
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF4F4F4F)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: ProfileHeader(userProfile: userProfile)),
                  SliverToBoxAdapter(child: ProfileInfoCard(userProfile: userProfile)),
                  const SliverToBoxAdapter(child: ProfileProgressSection()),
                  const SliverToBoxAdapter(child: ProfileAchievementsSection()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para las estrellas del fondo
class _Sparkles extends StatelessWidget {
  const _Sparkles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 30,
          child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 15),
        ),
        Positioned(
          top: 150,
          right: 40,
          child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 20),
        ),
        Positioned(
          top: 250,
          left: 60,
          child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 10),
        ),
         Positioned(
          top: 80,
          right: 90,
          child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 10),
        ),
      ],
    );
  }
}