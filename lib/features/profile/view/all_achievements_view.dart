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
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

// ✅ NUEVO: para color de avatar desde BD
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AllAchievementsView extends ConsumerStatefulWidget {
  final String userId;
  const AllAchievementsView({super.key, required this.userId});

  @override
  ConsumerState<AllAchievementsView> createState() =>
      _AllAchievementsViewState();
}

class _AllAchievementsViewState extends ConsumerState<AllAchievementsView>
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
    super.didChangeAppLifecycleState(state);
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

  // ✅ Color dinámico desde BD con fallback seguro
  Color _computeDynamicColor(
    UserProfileModel profile,
    ColorScheme colors,
  ) {
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    if (avatarsList.isNotEmpty) {
      return getAvatarColorById(profile.idAvatarSeleccionado, avatarsList);
    }
    return AllStatsView.getHeaderColor(profile, colors);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.watch(achievementRealtimeProvider);
    final currentAuthUserId =
        ref.watch(authStateProvider).value?.session?.user.id;

    if (currentAuthUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    final profileState = ref.watch(userProfileByIdProvider(widget.userId));
    final achievementsState = ref.watch(userAchievementsProvider(widget.userId));

    return VisibilityDetector(
      key: Key('all-achievements-detector-${widget.userId}'),
      onVisibilityChanged: (visibilityInfo) {
        setState(() {
          _isPageVisible = visibilityInfo.visibleFraction > 0.1;
          _updateAnimationState();
        });
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: profileState.when(
          loading: () => _AchievementsLoadingShimmer(colors: colors),
          error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
          data: (profile) {
            final isCurrentUser = widget.userId == currentAuthUserId;
            final dynamicColor = _computeDynamicColor(profile, colors);

            return Stack(
              children: [
                // --- Fondo degradado con color del avatar (BD) ---
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

                // --- Lottie tintado (sin withOpacity deprecado) ---
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    colors.secondaryFixedDim.withAlpha((255 * 0.8).round()),
                    BlendMode.srcIn,
                  ),
                  child: Lottie.asset(
                    'assets/animations/spring.json',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    controller: _lottieController,
                    onLoaded: (composition) {
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
                            horizontal: 16.0, vertical: 8.0),
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
                                'Todos los Logros',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Grid de logros
                      Expanded(
                        child: achievementsState.when(
                          loading: () =>
                              _AchievementsLoadingShimmer(colors: colors),
                          error: (e, s) => Center(
                              child: Text('Error al cargar logros: $e')),
                          data: (achievements) {
                            return _AchievementsGrid(
                              achievements: achievements,
                              colors: colors,
                              profile: profile,
                              isCurrentUser: isCurrentUser,
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

class _AchievementsGrid extends StatelessWidget {
  final List<UserAchievementModel> achievements;
  final ColorScheme colors;
  final UserProfileModel profile;
  final bool isCurrentUser;

  const _AchievementsGrid({
    required this.achievements,
    required this.colors,
    required this.profile,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements =
        achievements.where((a) => a.obtenido).toList();
    final lockedAchievements =
        achievements.where((a) => !a.obtenido).toList();

    final totalCount = achievements.length;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      children: [
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

        if (unlockedAchievements.isNotEmpty) ...[
          _buildSectionHeader(
            textTheme,
            'Desbloqueados',
            Icons.lock_open_rounded,
          ),
          _buildGridView(unlockedAchievements),
        ],

        if (lockedAchievements.isNotEmpty) ...[
          _buildSectionHeader(
            textTheme,
            'Bloqueados',
            Icons.lock_outline_rounded,
          ),
          _buildGridView(lockedAchievements),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(TextTheme textTheme, String title, IconData icon) {
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

  Widget _buildGridView(List<UserAchievementModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      cacheExtent: 100.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final achievement = items[index];
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

class _AchievementsLoadingShimmer extends StatelessWidget {
  final ColorScheme colors;
  const _AchievementsLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceContainerHigh,
        highlightColor: colors.surfaceContainerHighest,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
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
                    width: 250,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
