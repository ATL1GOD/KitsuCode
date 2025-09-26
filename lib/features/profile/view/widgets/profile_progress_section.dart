import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ProfileProgressSection extends ConsumerWidget {
  const ProfileProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsState = ref.watch(userStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
              'Progreso',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.secondary, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.push('/all-stats'),
              child: const Text('Ver todo'),
              ),
            ],
            ),
          const SizedBox(height: 10),
          statsState.when(
            loading: () => const _ProgressLoadingShimmer(),
            error: (error, stack) => const Center(child: Text('No se pudo cargar el progreso.')),
            data: (stats) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.article_outlined,
                          value: stats.retosCompletados.toString(),
                          label: 'Retos',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_outlined,
                          value: stats.rachaDias.toString(),
                          label: 'Racha',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          value: '${stats.porcentajeAciertos.toStringAsFixed(1)}%',
                          label: 'Aciertos',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.cancel_outlined,
                          value: '${stats.porcentajeFallos.toStringAsFixed(1)}%', 
                          label: 'Errores',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

// --- WIDGET DE LA TARJETA DE ESTADÍSTICAS ---
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      
      color: colors.surfaceVariant.withOpacity(0.5),
      elevation: 0, 
      shape: RoundedRectangleBorder(
        
        side: BorderSide(color: colors.primaryContainer.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
// --- WIDGET DE SHIMMER PARA EL ESTADO DE CARGA
class _ProgressLoadingShimmer extends StatelessWidget {
  const _ProgressLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _ShimmerCard()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _ShimmerCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5, 
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}