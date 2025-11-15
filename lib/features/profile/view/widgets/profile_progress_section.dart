import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kitsucode/shared/widgets/optimized_glass_card.dart';

class ProfileProgressSection extends ConsumerWidget {
  final String userId;
  final bool showViewAllButton;
  final bool enableGlassEffect;

  const ProfileProgressSection({
    super.key,
    required this.userId,
    this.showViewAllButton = true,
    this.enableGlassEffect = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsState = ref.watch(userStatsByIdProvider(userId));

    return OptimizedGlassCard(
      enableGlassEffect: enableGlassEffect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // icono y título
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart, // Icono de estadísticas
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 8), // Espacio entre icono y texto
                      Text('Progreso', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  // --- TERMINA EL CAMBIO ---
                  if (showViewAllButton)
                    TextButton(
                      onPressed: () => context.push('/all-stats'),
                      child: Text('Ver todo', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            statsState.when(
              loading: () => const _ProgressLoadingShimmer(),
              error: (error, stack) => const Center(child: Text('No se pudo cargar el progreso.')),
              data: (stats) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactStat(icon: Icons.article_outlined, value: stats.retosCompletados.toString(), label: 'Retos'),
                    _CompactStat(icon: Icons.local_fire_department_outlined, value: stats.rachaDias.toString(), label: 'Racha'),
                    _CompactStat(icon: Icons.check_circle_outline, value: '${stats.porcentajeAciertos.toStringAsFixed(0)}%', label: 'Aciertos'),
                    _CompactStat(icon: Icons.cancel_outlined, value: '${stats.porcentajeFallos.toStringAsFixed(0)}%', label: 'Errores'),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CompactStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withAlpha(204)),
        ),
      ],
    );
  }
}

// _GlassCard removido - ahora usamos OptimizedGlassCard compartido

class _ProgressLoadingShimmer extends StatelessWidget {
  const _ProgressLoadingShimmer();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          4,
          (index) => Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}