// lib/features/competences/view/ranking_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/competences/view/widgets/ranking_error_widget.dart';
import 'package:kitsucode/features/competences/view/widgets/ranking_filters_widget.dart';
import 'package:kitsucode/features/competences/view/widgets/ranking_tile.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart'; // ✅ TIPADO
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Solo se usa para los avatares (podium / tiles)
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class RankingView extends ConsumerWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(followRealtimeProvider);
    ref.watch(realtimeUpdateProvider);
    final authState = ref.watch(authStateProvider);
    final isLogged = authState.value?.session != null;

    if (!isLogged) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clasificación')),
        body: _buildNotAuthenticatedScreen(context),
      );
    }
    return const Scaffold(body: _RankingContent());
  }

  Widget _buildNotAuthenticatedScreen(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: colors.secondary),
            const SizedBox(height: 20),
            Text(
              'Para acceder a esta sección, primero debes iniciar sesión.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingContent extends ConsumerStatefulWidget {
  const _RankingContent();

  @override
  ConsumerState<_RankingContent> createState() => _RankingContentState();
}

class _RankingContentState extends ConsumerState<_RankingContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _lottieController;
  late final AnimationController _decorativeBgController;

  bool _isTabVisible = true;
  bool _isAppActive = true;
  bool _isLottieLoaded = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _decorativeBgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _decorativeBgController.dispose();
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
    if (_isAppActive && _isTabVisible && _isLottieLoaded) {
      _lottieController.repeat();
    } else {
      _lottieController.stop();
    }

    if (_isAppActive && _isTabVisible) {
      _decorativeBgController.repeat(reverse: true);
    } else {
      _decorativeBgController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ✅ Traemos y TIPAMOS la lista de avatares para resolver asset_path/URL
    final List<AvatarModel>? avatarsList =
        ref.watch(currentUserAvatarsProvider).value?.cast<AvatarModel>();

    final rankingAsync = ref.watch(globalRankingProvider);
    final authUser = ref.watch(authStateProvider).value?.session?.user;
    final String? currentUserId = authUser?.id;

    return VisibilityDetector(
      key: const Key('ranking-view-detector'),
      onVisibilityChanged: (visibilityInfo) {
        setState(() {
          _isTabVisible = visibilityInfo.visibleFraction > 0.1;
          _updateAnimationState();
        });
      },
      child: Scaffold(
        backgroundColor: colors.primaryContainer.withValues(alpha: .05), // ⚙️
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Lottie.asset(
                  'assets/animations/background_train.json',
                  fit: BoxFit.cover,
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController.duration = composition.duration;
                    _isLottieLoaded = true;
                    _updateAnimationState();
                  },
                ),
              ),
            ),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
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
                                    color:
                                        colors.outlineVariant.withAlpha(130),
                                  ),
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                    color: colors.onSurface),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Tabla de Clasificación',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      const RankingFiltersWidget(),
                    ],
                  ),
                ),
                Expanded(
                  child: rankingAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) =>
                        Center(child: RankingErrorWidget(error: e)),
                    data: (ranking) {
                      if (ranking.isEmpty) return const _EmptyRankingWidget();
                      final top3 = ranking.length >= 3
                          ? ranking.sublist(0, 3)
                          : ranking;
                      final restOfRanking = ranking.length > 3
                          ? ranking.sublist(3)
                          : <RankingModel>[];
                      final currentUserData = (currentUserId == null)
                          ? null
                          : ranking
                              .where((user) => user.userId == currentUserId)
                              .firstOrNull;

                      return Stack(
                        children: [
                          Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 0),
                                    height: 280,
                                    decoration: BoxDecoration(
                                      color: colors.surface.withValues(
                                          alpha: .10), // ⚙️
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: _DecorativeBackground(
                                      controller: _decorativeBgController,
                                    ),
                                  ),
                                  if (top3.isNotEmpty)
                                    _PodiumWidget(
                                      users: top3,
                                      colors: colors,
                                      currentUserId: currentUserId,
                                      avatarsList: avatarsList, // ✅ pasa lista
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.leaderboard_outlined,
                                        color: colors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Clasificación General',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 4, bottom: 160),
                                  itemCount: restOfRanking.length,
                                  itemBuilder: (context, index) {
                                    final user = restOfRanking[index];
                                    return FadeInUp(
                                      delay:
                                          Duration(milliseconds: index * 30),
                                      child: RankingTile(
                                        user: user,
                                        isCurrentUser:
                                            user.userId == currentUserId,
                                        colors: colors,
                                        // AÑADIDO AQUÍ 👇
                                        avatarsList: avatarsList,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (currentUserData != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _CurrentUserBanner(
                                user: currentUserData,
                                colors: colors,
                                // AÑADIDO AQUÍ 👇
                                avatarsList: avatarsList,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRankingWidget extends StatelessWidget {
  const _EmptyRankingWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/login_zorro.png',
              width: 150,
              color: colors.primaryContainer.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay usuarios en este ranking aún.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeBackground extends StatefulWidget {
  final AnimationController controller;
  const _DecorativeBackground({required this.controller});

  @override
  State<_DecorativeBackground> createState() => _DecorativeBackgroundState();
}

class _DecorativeBackgroundState extends State<_DecorativeBackground> {
  late final List<Animation<Alignment>> _animations;

  @override
  void initState() {
    super.initState();
    _animations = [
      _createTween(const Alignment(-1, -0.8), const Alignment(1, -0.7))
          .animate(_createCurve(0.0, 0.5)),
      _createTween(const Alignment(1.2, -0.2), const Alignment(-1.2, 0))
          .animate(_createCurve(0.2, 0.7)),
      _createTween(const Alignment(0, 1.1), const Alignment(0, -1.1))
          .animate(_createCurve(0.4, 1.0)),
      _createTween(const Alignment(1.1, 1), const Alignment(-1.1, 0.8))
          .animate(_createCurve(0.1, 0.8)),
      _createTween(const Alignment(-1.3, 0.9), const Alignment(1.3, -0.9))
          .animate(_createCurve(0.3, 0.9)),
    ];
  }

  AlignmentTween _createTween(Alignment begin, Alignment end) =>
      AlignmentTween(begin: begin, end: end);

  CurvedAnimation _createCurve(double begin, double end) => CurvedAnimation(
        parent: widget.controller,
        curve: Interval(begin, end, curve: Curves.easeInOutSine),
      );

  Widget _buildIcon(
      String assetPath, Animation<Alignment> animation, double size) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) =>
          Align(alignment: animation.value, child: child),
      child: Opacity(
        opacity: 0.1,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          _buildIcon('assets/images/logo_python.webp', _animations[0], 50),
          _buildIcon('assets/images/logo_java.webp', _animations[1], 60),
          _buildIcon('assets/images/logo_c.webp', _animations[2], 70),
          _buildIcon('assets/images/logo_python.webp', _animations[3], 40),
          _buildIcon('assets/images/logo_java.webp', _animations[4], 55),
        ],
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<RankingModel> users;
  final ColorScheme colors;
  final String? currentUserId;
  final List<AvatarModel>? avatarsList; // ✅ lista tipada

  const _PodiumWidget({
    required this.users,
    required this.colors,
    required this.currentUserId,
    required this.avatarsList,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (users.length > 1)
              _PodiumPlace(
                user: users[1],
                place: 2,
                color: Colors.grey.shade400,
                heightFactor: 0.7,
                isCurrentUser: users[1].userId == currentUserId,
                avatarsList: avatarsList,
              ),
            if (users.isNotEmpty)
              _PodiumPlace(
                user: users[0],
                place: 1,
                color: Colors.amber.shade400,
                heightFactor: 1.0,
                isCurrentUser: users[0].userId == currentUserId,
                avatarsList: avatarsList,
              ),
            if (users.length > 2)
              _PodiumPlace(
                user: users[2],
                place: 3,
                color: Colors.brown.shade400,
                heightFactor: 0.55,
                isCurrentUser: users[2].userId == currentUserId,
                avatarsList: avatarsList,
              ),
          ],
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final RankingModel user;
  final int place;
  final Color color;
  final double heightFactor;
  final bool isCurrentUser;
  final List<AvatarModel>? avatarsList; // ✅

  const _PodiumPlace({
    required this.user,
    required this.place,
    required this.color,
    required this.heightFactor,
    required this.isCurrentUser,
    required this.avatarsList,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = 110.0 * heightFactor;

    // ✅ Usa la misma resolución que en el modal (con lista tipada si existe)
    final String avatarPath =
        getAvatarAssetPathById(user.idAvatarSeleccionado, avatarsList);

    return GestureDetector(
      onTap: () {
        if (isCurrentUser) return;
        showDialog(
          context: context,
          builder: (ctx) =>
              UserProfileModal(userId: user.userId, rank: user.rank),
        );
      },
      child: FadeInUp(
        delay: Duration(milliseconds: 100 * (4 - place)),
        child: SizedBox(
          width: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (place == 1) Icon(Icons.emoji_events, color: color, size: 32),
              if (place != 1) const SizedBox(height: 32),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: size / 2,
                    backgroundColor: color,
                    child: CircleAvatar(
                      radius: (size / 2) - 4,
                      backgroundColor: Colors.black12,
                      child: ClipOval(
                        child: avatarPath.isEmpty
                            ? const ColoredBox(color: Colors.transparent)
                            : OptimizedImage(
                                imagePath: avatarPath,
                                width: size - 8,
                                height: size - 8,
                                fit: BoxFit.cover,
                                enableCache: true,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: color,
                      child: Text(
                        '$place',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.profileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${user.totalScore} Pts',
                style: textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentUserBanner extends StatelessWidget {
  final RankingModel user;
  final ColorScheme colors;
  final List<AvatarModel>? avatarsList; // <--- AÑADIDO AQUÍ

  const _CurrentUserBanner({
    required this.user,
    required this.colors,
    this.avatarsList, // <--- AÑADIDO AL CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          left: 8,
          right: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: colors.primaryContainer,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withAlpha(77),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: RankingTile(
          user: user,
          isCurrentUser: true,
          colors: colors,
          avatarsList: avatarsList, // <--- PASADO AL TILE
        ),
      ),
    );
  }
}