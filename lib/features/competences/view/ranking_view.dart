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
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
  
  // 🔥 1. NUEVO ESTADO: Controla si hay un modal abierto
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _decorativeBgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
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
    if (!mounted) return;
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
      _updateAnimationState();
    });
  }

  // 🔥 2. LÓGICA DE PAUSA: Ahora considera _isModalOpen
  void _updateAnimationState() {
    // Solo animamos si la app está activa, la tab visible Y NO hay modal abierto
    final shouldAnimate = _isAppActive && _isTabVisible && !_isModalOpen;

    if (shouldAnimate && _isLottieLoaded) {
      if (!_lottieController.isAnimating) _lottieController.repeat();
    } else {
      if (_lottieController.isAnimating) _lottieController.stop();
    }

    if (shouldAnimate) {
      if (!_decorativeBgController.isAnimating) {
        _decorativeBgController.repeat(reverse: true);
      }
    } else {
      if (_decorativeBgController.isAnimating) _decorativeBgController.stop();
    }
  }

  // 🔥 3. FUNCIÓN MAESTRA: Abre el modal y pausa/reanuda animaciones
  Future<void> _onUserTap(RankingModel user, String? currentUserId) async {
    // No abrir modal si soy yo mismo (opcional, según tu lógica)
    if (user.userId == currentUserId) return;

    // 1. Pausar animaciones
    setState(() {
      _isModalOpen = true;
      _updateAnimationState();
    });

    // 2. Esperar a que se cierre el diálogo
    await showDialog(
      context: context,
      builder: (ctx) => UserProfileModal(userId: user.userId, rank: user.rank),
    );

    // 3. Reanudar animaciones
    if (mounted) {
      setState(() {
        _isModalOpen = false;
        _updateAnimationState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<AvatarModel>? avatarsList = ref
        .watch(currentUserAvatarsProvider)
        .value
        ?.cast<AvatarModel>();

    final rankingAsync = ref.watch(globalRankingProvider);
    final authUser = ref.watch(authStateProvider).value?.session?.user;
    final String? currentUserId = authUser?.id;

    return VisibilityDetector(
      key: const Key('ranking-view-detector'),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return;
        setState(() {
          _isTabVisible = visibilityInfo.visibleFraction > 0.1;
          _updateAnimationState();
        });
      },
      child: Scaffold(
        backgroundColor: colors.primaryContainer.withValues(alpha: .05),
        body: Stack(
          children: [
            // FONDO LOTTIE
            Positioned.fill(
              child: Opacity(
                opacity: 0.25, // 🔥 Reducido de 0.4 para menor costo de blending
                child: RepaintBoundary(
                  child: Lottie.asset(
                    'assets/animations/background_train.json',
                    fit: BoxFit.cover,
                    controller: _lottieController,
                    frameRate: FrameRate(30), // 🔥 Limitado a 30fps máximo
                    onLoaded: (composition) {
                      _lottieController.duration = composition.duration;
                      _isLottieLoaded = true;
                      _updateAnimationState();
                    },
                  ),
                ),
              ),
            ),
            Column(
  children: [
    SafeArea(
      bottom: false,
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // ✅ SizedBox vacío para mantener el balance visual
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    'Tabla de Clasificación',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  // PODIUM
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                            16, 8, 16, 0),
                        height: 280,
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        // 🔥 RepaintBoundary para el fondo decorativo
                        child: RepaintBoundary(
                          child: _DecorativeBackground(
                            controller: _decorativeBgController,
                          ),
                        ),
                      ),
                      if (top3.isNotEmpty)
                        _PodiumWidget(
                          users: top3,
                          colors: colors,
                          currentUserId: currentUserId,
                          avatarsList: avatarsList,
                          // 🔥 Pasamos la función de tap
                          onUserTap: (user) => _onUserTap(user, currentUserId),
                        ),
                    ],
                  ),
                  // TÍTULO LISTA
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clasificación General',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // LISTA RESTANTE
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 160,
                      ),
                      // 🔥 OPTIMIZACIONES DE RENDIMIENTO
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      cacheExtent: 300,
                      itemCount: restOfRanking.length,
                      itemBuilder: (context, index) {
                        final user = restOfRanking[index];
                        // 🔥 Envolvemos en GestureDetector para usar nuestra función _onUserTap
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 30),
                          child: GestureDetector(
                            onTap: () => _onUserTap(user, currentUserId),
                            child: RankingTile(
                              user: user,
                              isCurrentUser:
                                  user.userId == currentUserId,
                              colors: colors,
                              avatarsList: avatarsList,
                            ),
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
              'assets/images/zorro_oops.png',
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
    // Las animaciones se basan en el controlador del padre, que pausamos/reanudamos arriba
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
    String assetPath,
    Animation<Alignment> animation,
    double size,
  ) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) =>
            Align(alignment: animation.value, child: child),
        child: Opacity(
          opacity: 0.08, // 🔥 Reducido de 0.1 para menor costo visual
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: (size * 2).toInt(), // 🔥 Cacheo eficiente
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 🔥 OPTIMIZADO: Reducido de 5 a 3 iconos para menor costo de animación
            _buildIcon('assets/images/home/logo_python.webp', _animations[0], 50),
            _buildIcon('assets/images/home/logo_java.webp', _animations[1], 60),
            _buildIcon('assets/images/home/logo_c.webp', _animations[2], 70),
          ],
        ),
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<RankingModel> users;
  final ColorScheme colors;
  final String? currentUserId;
  final List<AvatarModel>? avatarsList;
  // 🔥 Callback recibido del padre
  final Function(RankingModel) onUserTap; 

  const _PodiumWidget({
    required this.users,
    required this.colors,
    required this.currentUserId,
    required this.avatarsList,
    required this.onUserTap,
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
                onTap: () => onUserTap(users[1]), // 🔥
              ),
            if (users.isNotEmpty)
              _PodiumPlace(
                user: users[0],
                place: 1,
                color: Colors.amber.shade400,
                heightFactor: 1.0,
                isCurrentUser: users[0].userId == currentUserId,
                avatarsList: avatarsList,
                onTap: () => onUserTap(users[0]), // 🔥
              ),
            if (users.length > 2)
              _PodiumPlace(
                user: users[2],
                place: 3,
                color: Colors.brown.shade400,
                heightFactor: 0.55,
                isCurrentUser: users[2].userId == currentUserId,
                avatarsList: avatarsList,
                onTap: () => onUserTap(users[2]), // 🔥
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
  final List<AvatarModel>? avatarsList;
  final VoidCallback onTap; // 🔥 Callback simple

  const _PodiumPlace({
    required this.user,
    required this.place,
    required this.color,
    required this.heightFactor,
    required this.isCurrentUser,
    required this.avatarsList,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = 110.0 * heightFactor;

    final String avatarPath = getAvatarAssetPathById(
      user.idAvatarSeleccionado,
      avatarsList,
    );

    return GestureDetector(
      onTap: onTap, // 🔥 Usamos el callback pasado
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.profileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${user.totalScore} Pts',
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
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
  final List<AvatarModel>? avatarsList;

  const _CurrentUserBanner({
    required this.user,
    required this.colors,
    this.avatarsList,
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
        // Nota: El banner de usuario actual no necesita onTap porque eres tú mismo
        child: RankingTile(
          user: user,
          isCurrentUser: true,
          colors: colors,
          avatarsList: avatarsList,
        ),
      ),
    );
  }
}