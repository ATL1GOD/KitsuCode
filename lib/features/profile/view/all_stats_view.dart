// lib/features/profile/view/all_stats_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class AllStatsView extends ConsumerWidget {
  const AllStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- CAMBIO 1: OBTENER EL ID DEL USUARIO PRIMERO ---
    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    // --- CAMBIO 2: PASAR EL ID A AMBOS PROVIDERS ---
    final statsState = ref.watch(userStatsProvider(currentUserId));
    final profileState = ref.watch(userProfileByIdProvider(currentUserId));

    return Scaffold(
      body: Stack(
        children: [
          const LoginBackground(child: SizedBox.shrink()),
          SafeArea(
            child: statsState.when(
              loading: () => const _StatsLoadingShimmer(),
              error: (e, s) => Center(child: Text('Error al cargar estadísticas: $e')),
              data: (stats) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
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
                          Expanded(
                            child: Text(
                              'Estadísticas',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 40), // Para centrar el título
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        children: [
                          profileState.when(
                            data: (profile) => FadeInDown(
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
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
                            loading: () => const SizedBox(height: 60),
                            error: (e,s) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 30),
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
                              title: 'Porcentaje de Aciertos',
                              value: '${stats.porcentajeAciertos.toStringAsFixed(1)}%',
                              color: Colors.green.shade600,
                            ),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            child: _StatDisplayCard(
                              icon: Icons.cancel_outlined,
                              title: 'Porcentaje de Errores',
                              value: '${stats.porcentajeFallos.toStringAsFixed(1)}%',
                              color: colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE LA TARJETA DE ESTADÍSTICA
class _StatDisplayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatDisplayCard({ required this.icon, required this.title, required this.value, required this.color });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: colors.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFF1E1D0).withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DE SHIMMER PARA EL ESTADO DE CARGA ---
class _StatsLoadingShimmer extends StatelessWidget {
  const _StatsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 4,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const SizedBox(height: 90),
        ),
      ),
    );
  }
}