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
// import 'package:kitsucode/features/profile/view/widgets/achievement_modal.dart'; // No se usa aquí
import 'package:animate_do/animate_do.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // No se usa aquí
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';


class AllAchievementsView extends ConsumerWidget {
  final String userId;
  const AllAchievementsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Activamos el listener de realtime
    ref.watch(achievementRealtimeProvider);

    // Obtenemos el ID del usuario actual (el que usa la app)
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentAuthUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    // Observamos el perfil que se está viendo
    final profileState = ref.watch(userProfileByIdProvider(userId));
    // Observamos los logros de ESE perfil
    final achievementsState = ref.watch(userAchievementsProvider(userId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _AchievementsLoadingShimmer(colors: colors), // Pasamos colors al shimmer
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          // ¡Calculamos si es el usuario actual!
          // Asumiendo que tu UserProfileModel SÍ tiene un campo 'id'
          // Esta línea es la correcta
          final isCurrentUser = userId == currentAuthUserId;
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- FONDO ---
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
                  colors.secondaryFixedDim.withOpacity(0.8), // Usando 'withOpacity' corregido si es necesario
                  BlendMode.srcIn, 
                ),
                child: Lottie.asset(
                  'assets/animations/spring.json', 
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              
              // --- CONTENIDO PRINCIPAL ---
              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR ---
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
                          const SizedBox(width: 48), // Espacio para centrar el título
                        ],
                      ),
                    ),

                    // --- CONTENIDO (LA CUADRÍCULA) ---
                    Expanded(
                      child: achievementsState.when(
                        loading: () => _AchievementsLoadingShimmer(colors: colors),
                        error: (e, s) => Center(child: Text('Error al cargar logros: $e')),
                        data: (achievements) {
                          return _AchievementsGrid(
                            achievements: achievements, 
                            colors: colors,
                            profile: profile, // ✅ Pasamos el perfil
                            isCurrentUser: isCurrentUser, // ✅ Pasamos el booleano
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

// --- WIDGET PARA LA CUADRÍCULA DE LOGROS ---
// --- WIDGET PARA LA CUADRÍCULA DE LOGROS (CON SECCIONES SEPARADAS) ---
class _AchievementsGrid extends StatelessWidget {
  final List<UserAchievementModel> achievements;
  final ColorScheme colors;
  final UserProfileModel profile; // ✅ Recibimos el perfil
  final bool isCurrentUser;      // ✅ Recibimos el booleano

  const _AchievementsGrid({
    required this.achievements,
    required this.colors,
    required this.profile,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
    // 1. Separamos las listas en lugar de solo ordenarlas
    final unlockedAchievements =
        achievements.where((a) => a.obtenido).toList();
    final lockedAchievements =
        achievements.where((a) => !a.obtenido).toList();

    final totalCount = achievements.length;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      children: [
        // --- Información de resumen (igual que antes) ---
        FadeInDown(
          child: Column(
            children: [
              Text(
                profile.nombrePerfil,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${unlockedAchievements.length} / $totalCount Logros Desbloqueados',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // --- SECCIÓN 1: DESBLOQUEADOS ---
        if (unlockedAchievements.isNotEmpty) ...[
          _buildSectionHeader(
            textTheme,
            'Desbloqueados',
            Icons.lock_open_rounded,
          ),
          _buildGridView(unlockedAchievements),
        ],

        // --- SECCIÓN 2: PENDIENTES ---
        if (lockedAchievements.isNotEmpty) ...[
          _buildSectionHeader(
            textTheme,
            'Bloqueados',
            Icons.lock_outline_rounded,
          ),
          _buildGridView(lockedAchievements),
        ],

        // Espacio extra al final para que no quede pegado
        const SizedBox(height: 40),
      ],
    );
  }

  // --- WIDGET HELPER PARA LOS TÍTULOS ---
  Widget _buildSectionHeader(
      TextTheme textTheme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 16.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER PARA LA CUADRÍCULA ---
  Widget _buildGridView(List<UserAchievementModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final achievement = items[index];
        // Usamos un delay menor para la segunda sección si quisiéramos,
        // pero 50ms por item se ve bien.
        return FadeInUp(
          delay: Duration(milliseconds: 30 * index),
          duration: const Duration(milliseconds: 400),
          child: AchievementCard(
            achievement: achievement,
            colors: colors,
            isCompactView: false,
            isClickable: true,
            profile: profile,
            isCurrentUser: isCurrentUser,
          ),
        );
      },
    );
  }
}

// --- SHIMMER DE CARGA ---
class _AchievementsLoadingShimmer extends StatelessWidget {
  final ColorScheme colors;
  const _AchievementsLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors( 
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // No permitir scroll
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 60), // Espacio para el appbar
            Column(
              children: [
                Container(
                  width: 180, 
                  height: 30, 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(8)
                  )
                ),
                const SizedBox(height: 15),
                Container(
                  width: 250, 
                  height: 25, 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(8)
                  )
                ),
              ],
            ),
            const SizedBox(height: 30),
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
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(12)
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}