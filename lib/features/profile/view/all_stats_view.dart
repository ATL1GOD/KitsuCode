import 'dart:ui'; // Necesario para ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart'; // Necesario para getHeaderColor
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class AllStatsView extends ConsumerWidget {
  const AllStatsView({super.key});

  // --- Lógica para el color dinámico, traída de ProfileView ---
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }
    
    final statsState = ref.watch(userStatsProvider(currentUserId));
    final profileState = ref.watch(userProfileByIdProvider(currentUserId));

    return Scaffold(
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          final dynamicColor = getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- CAMBIO: Fondo degradado dinámico ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha(102),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.6]
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // --- CAMBIO: Barra de navegación con estilo consistente ---
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
                                color: colors.surface.withAlpha(77),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Estadísticas',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48), // Espacio para centrar el título
                        ],
                      ),
                    ),

                    Expanded(
                      child: statsState.when(
                        loading: () => const _StatsLoadingShimmer(),
                        error: (e, s) => Center(child: Text('Error al cargar estadísticas: $e')),
                        data: (stats) {
                          return ListView(
                            padding: const EdgeInsets.all(20.0),
                            children: [
                              FadeInDown(
                                child: Column(
                                  children: [
                                    Text(profile.nombrePerfil, style: textTheme.headlineSmall),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () { /* TODO: Navegar al historial */ },
                                      icon: const Icon(Icons.history, size: 20),
                                      label: const Text('Ver historial'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primaryContainer,
                                        foregroundColor: colors.onPrimaryContainer,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              // --- CAMBIO: Tarjetas de cristal ---
                              _GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 200),
                                        child: _StatDisplayCard(
                                          icon: Icons.article_outlined,
                                          title: 'Retos Completados',
                                          value: stats.retosCompletados.toString(),
                                          color: colors.secondary,
                                        ),
                                      ),
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 300),
                                        child: _StatDisplayCard(
                                          icon: Icons.local_fire_department_outlined,
                                          title: 'Racha de Días',
                                          value: stats.rachaDias.toString(),
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 400),
                                        child: _StatDisplayCard(
                                          icon: Icons.check_circle_outline,
                                          title: 'Aciertos',
                                          value: '${stats.porcentajeAciertos.toStringAsFixed(1)}%',
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 500),
                                        child: _StatDisplayCard(
                                          icon: Icons.cancel_outlined,
                                          title: 'Errores',
                                          value: '${stats.porcentajeFallos.toStringAsFixed(1)}%',
                                          color: colors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                )
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- WIDGET DE LA TARJETA DE ESTADÍSTICA (ahora sin Card y más compacto) ---
class _StatDisplayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatDisplayCard({ required this.icon, required this.title, required this.value, required this.color });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withAlpha(38),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// --- WIDGET AÑADIDO: TARJETA DE CRISTAL ---
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(102),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(128))
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- CAMBIO: WIDGET DE SHIMMER ADAPTADO ---
class _StatsLoadingShimmer extends StatelessWidget {
  const _StatsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Shimmer para el nombre y botón
          Shimmer.fromColors(
             baseColor: Colors.grey[400]!,
             highlightColor: Colors.grey[200]!,
             child: Column(
               children: [
                 Container(width: 150, height: 24, color: Colors.white),
                 const SizedBox(height: 10),
                 Container(width: 120, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
               ],
             )
          ),
          const SizedBox(height: 30),
          // Shimmer para la tarjeta de cristal
          Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.grey[200]!,
            child: const _GlassCard(
              child: SizedBox(
                height: 400, // Altura aproximada de la tarjeta
                width: double.infinity,
              )
            ),
          ),
        ],
      ),
    );
  }
}