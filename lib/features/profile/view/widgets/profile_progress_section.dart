import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ProfileProgressSection extends ConsumerWidget {
  final bool showViewAllButton;
  const ProfileProgressSection({super.key, this.showViewAllButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsState = ref.watch(userStatsProvider);

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withOpacity(0.8)),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5))
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProgressLoadingShimmer extends StatelessWidget {
  const _ProgressLoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[200]!,
      child: const SizedBox(height: 70, child: Placeholder()),
    );
  }
}