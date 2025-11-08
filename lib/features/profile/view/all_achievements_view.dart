// lib/features/profile/view/all_achievements_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart'; 
import 'package:kitsucode/features/profile/view/widgets/achievement_card.dart';
import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart'; // Asegura la importación


class AllAchievementsView extends ConsumerWidget {
  final String userId;
  const AllAchievementsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    final profileState = ref.watch(userProfileByIdProvider(userId));
    final achievementsState = ref.watch(userAchievementsProvider(userId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const _AchievementsLoadingShimmer(),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- FONDO (Similar a AllStatsView) ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha(100),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.7]
                  ),
                ),
              ),

              // --- ANIMACIÓN DE FONDO CON LOTTIE ---
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.secondaryFixedDim.withOpacity(0.8),
                  BlendMode.srcIn, 
                ),
                child: Lottie.asset(
                  'assets/animations/spring.json', 
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR (HEADER) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: colors.surface.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.outlineVariant.withAlpha(130))
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Todos los Logros',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // --- CONTENIDO PRINCIPAL (LISTA DE LOGROS) ---
                    Expanded(
                      child: achievementsState.when(
                        loading: () => const _AchievementsLoadingShimmer(),
                        error: (e, s) => Center(child: Text('Error al cargar logros: $e')),
                        data: (achievements) {
                          return _AchievementsGrid(
                            achievements: achievements, 
                            colors: colors,
                            profileName: profile.nombrePerfil,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- WIDGET PARA LA CUADRÍCULA DE LOGROS OBTENIDOS/PENDIENTES ---
class _AchievementsGrid extends StatelessWidget {
  final List<UserAchievementModel> achievements;
  final ColorScheme colors;
  final String profileName;

  const _AchievementsGrid({
    required this.achievements,
    required this.colors,
    required this.profileName,
  });

  @override
  Widget build(BuildContext context) {
    final obtainedAchievements = achievements.where((a) => a.obtenido).toList();
    final unobtainedAchievements = achievements.where((a) => !a.obtenido).toList();
    
    final obtainedCount = obtainedAchievements.length;
    final totalCount = achievements.length;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Información de resumen
        FadeInDown(
          child: Column(
            children: [
              Text(
                profileName,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$obtainedCount / $totalCount Logros Desbloqueados',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),

        // --- SECCIÓN 1: LOGROS OBTENIDOS ---
        if (obtainedAchievements.isNotEmpty) ...[
          // ... (Este GridView déjalo como está, funciona bien)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: obtainedAchievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final achievement = obtainedAchievements[index];
              return FadeInUp(
                delay: Duration(milliseconds: 50 * index),
                child: AchievementCard( // <-- Este está bien (Opacity 1.0)
                  achievement: achievement,
                  colors: colors,
                  isCompactView: false,
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],

        // --- SECCIÓN 2: DESAFÍOS PENDIENTES (NO OBTENIDOS) ---
        if (unobtainedAchievements.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Desafíos Pendientes (${unobtainedAchievements.length})',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
          ),
          
          // ======== 💡 ¡EL HACK BUENO, AHORA SÍ! 💡 ========
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unobtainedAchievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final achievement = unobtainedAchievements[index];

              return FadeInUp(
                delay: Duration(milliseconds: 50 * index),

                // 1. Envolvemos todo en un GestureDetector LIMPIO
        child: GestureDetector(
          
          // ======== 👇 ¡LA LÍNEA QUE ARREGLA LA ZONA DE CLIC! 👇 ========
          // Esto hace que el GestureDetector capture el clic
          // aunque su hijo (IgnorePointer) lo esté ignorando.
          behavior: HitTestBehavior.opaque,
          // ======== 👆 ¡LA LÍNEA ES CLAVE AQUÍ! 👆 ========

          onTap: () {
            // ¡ESTE CONTEXTO SÍ ESTÁ LIMPIO!
            showDialog(
              context: context,
              barrierDismissible: true,
              barrierColor: Colors.black.withOpacity(0.6), 
              builder: (ctx) => AchievementModal(achievement: achievement),
            );
          },
          
          // 2. Apagamos TODOS los clics de la tarjeta "envenenada"
          child: IgnorePointer(
            child: AchievementCard(
              achievement: achievement,
              colors: colors,
              isCompactView: false, 
            ),
          ),
        ),
      );
    },
  ),
        ],
      ],
    );
  }
}

// --- WIDGET DE SHIMMER DE CARGA (Soluciona el error de clase no definida) ---
class _AchievementsLoadingShimmer extends StatelessWidget {
  const _AchievementsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors( 
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Column(
              children: [
                Container(width: 180, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 15),
                Container(width: 250, height: 25, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              ],
            ),
            const SizedBox(height: 30),
            // Cuadrícula de shimmer
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9, 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                return Container(
                  height: 160,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}