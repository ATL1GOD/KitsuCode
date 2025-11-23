// lib/features/profile/view/all_stats_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
// 🔥 Visibilidad
import 'package:visibility_detector/visibility_detector.dart';

class AllStatsView extends ConsumerStatefulWidget {
  const AllStatsView({super.key});

  // Mantén este helper como fallback
  static Color getHeaderColor(
    UserProfileModel userProfile,
    ColorScheme colors,
  ) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  @override
  ConsumerState<AllStatsView> createState() => _AllStatsViewState();
}

class _AllStatsViewState extends ConsumerState<AllStatsView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _lottieController;

  bool _isPageVisible = true;
  bool _isAppActive = true;
  bool _isLottieLoaded = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
      _updateAnimationState();
    });
  }

  void _updateAnimationState() {
    if (_isAppActive && _isPageVisible && _isLottieLoaded) {
      _lottieController.repeat();
    } else {
      _lottieController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    final statsState = ref.watch(userStatsByIdProvider(currentUserId));
    final profileState = ref.watch(userProfileByIdProvider(currentUserId));

    // 👇 Importante: evita setState tras dispose
    return VisibilityDetector(
      key: const Key('all-stats-detector'),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return;
        setState(() {
          _isPageVisible = visibilityInfo.visibleFraction > 0.1;
          _updateAnimationState();
        });
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: profileState.when(
          loading: () => const _StatsLoadingShimmer(),
          error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
          data: (profile) {
            // ✅ Color dinámico desde BD si ya está la lista de avatares; sino fallback
            final avatarsList =
                ref.watch(currentUserAvatarsProvider).value ?? [];
            final dynamicColor = avatarsList.isNotEmpty
                ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
                : AllStatsView.getHeaderColor(profile, colors);

            return Stack(
              children: [
                // Fondo degradado
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dynamicColor.withAlpha(100),
                        colors.surfaceContainerLowest,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),

                // Lottie con tinte y control seguro
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    // Reemplazo deprecado: withAlpha en vez de withAlpha(204)
                    colors.secondaryFixedDim.withAlpha((0.8 * 255).round()),
                    BlendMode.srcIn,
                  ),
                  child: Lottie.asset(
                    'assets/animations/spring.json',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    controller: _lottieController,
                    onLoaded: (composition) {
                      if (!mounted) return; // 👈 evita setState tras dispose
                      if (_lottieController.duration != composition.duration) {
                        _lottieController.duration = composition.duration;
                      }
                      _isLottieLoaded = true;
                      _updateAnimationState();
                    },
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // AppBar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
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
                                  border: Border.all(
                                    color: colors.outlineVariant.withAlpha(130),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Estadísticas',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Contenido
                      Expanded(
                        child: statsState.when(
                          loading: () => const _StatsLoadingShimmer(),
                          error: (e, s) => Center(
                            child: Text('Error al cargar estadísticas: $e'),
                          ),
                          data: (stats) {
                            return ListView(
                              padding: const EdgeInsets.all(20.0),
                              children: [
                                FadeInDown(
                                  child: Column(
                                    children: [
                                      Text(
                                        profile.nombrePerfil,
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          context.pushNamed(
                                            'challenge-history',
                                            pathParameters: {
                                              'userId': currentUserId,
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.history,
                                          size: 20,
                                        ),
                                        label: const Text('Ver historial'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: colors.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // 👉 Card con BORDE y AURA usando dynamicColor
                                _StatsCard(
                                      dynamicColor: dynamicColor, // 👈 añadido
                                      child: Column(
                                        children: [
                                          _StatRow(
                                            icon: Icons.shield_outlined,
                                            title: 'Retos Completados',
                                            value: stats.retosCompletados,
                                            color: colors.secondary,
                                            delay: 200.ms,
                                          ),
                                          _StatRow(
                                            icon: Icons.local_fire_department,
                                            title: 'Racha de Días',
                                            value: stats.rachaDias,
                                            color: colors.primary,
                                            delay: 300.ms,
                                          ),
                                          _StatRow(
                                            icon: Icons.check_circle_outline,
                                            title: 'Aciertos',
                                            value: stats.porcentajeAciertos,
                                            isPercentage: true,
                                            color: const Color(0xFF2E7D32),
                                            delay: 400.ms,
                                          ),
                                          _StatRow(
                                            icon: Icons.cancel_outlined,
                                            title: 'Errores',
                                            value: stats.porcentajeFallos,
                                            isPercentage: true,
                                            color: colors.error,
                                            delay: 500.ms,
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ],
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
      ),
    );
  }
}

// -------------------- Widgets auxiliares --------------------

class _StatsCard extends StatelessWidget {
  final Widget child;
  final Color? dynamicColor; // 👈 nuevo opcional (para no romper llamadas)
  const _StatsCard({required this.child, this.dynamicColor});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final aura =
        dynamicColor ?? c.primary; // si no pasan color, usa el primario

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainer.withAlpha(210),
        borderRadius: BorderRadius.circular(24),
        // 👇 borde con tinte del avatar
        border: Border.all(color: aura.withAlpha(185), width: 1.6),
        boxShadow: [
          // 👇 “aura” suave del color dinámico
          BoxShadow(
            color: aura.withAlpha(72), // ~28% opacidad
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 7),
          ),
          // sombra base discreta
          BoxShadow(
            color: c.shadow.withAlpha(22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: _StatsCardChildProxy(),
      ).copyWithChild(child), // truco para mantener padding constante
    );
  }
}

/// Pequeño helper para poder “reemplazar” el child sin duplicar padding.
class _StatsCardChildProxy extends StatelessWidget {
  const _StatsCardChildProxy();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

extension on Widget {
  /// Devuelve el mismo widget pero reemplazando el `child` del Padding superior.
  /// (Nos evita reescribir el Padding en cada edición)
  Widget copyWithChild(Widget child) {
    if (this is Padding) {
      final p = this as Padding;
      return Padding(padding: p.padding, child: child);
    }
    return child;
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final num value;
  final Color color;
  final bool isPercentage;
  final Duration delay;

  const _StatRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isPercentage = false,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: isPercentage
                          ? (value.clamp(0, 100) / 100)
                          : 0.75,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color.withAlpha(130),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) => Text(
                isPercentage
                    ? '${animatedValue.toStringAsFixed(1)}%'
                    : animatedValue.toInt().toString(),
                textAlign: TextAlign.right,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay, duration: 500.ms).slideX(begin: -0.2);
  }
}

class _StatsLoadingShimmer extends StatelessWidget {
  const _StatsLoadingShimmer();

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
                Container(
                  width: 180,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: 140,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
