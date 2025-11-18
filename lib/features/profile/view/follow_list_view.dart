// lib/features/profile/view/follow_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/follow_list_model.dart';
import 'package:kitsucode/features/profile/provider/follow_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kitsucode/main.dart' show routeObserver;
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class FollowListView extends ConsumerStatefulWidget {
  final String userId;
  final String type; // 'following' o 'followers'

  const FollowListView({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  ConsumerState<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends ConsumerState<FollowListView> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshList();
  }

  void _refreshList() {
    final args = FollowListArgs(userId: widget.userId, type: widget.type);
    ref.invalidate(followListProvider(args));
    ref.invalidate(userProfileByIdProvider(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final profileState = ref.watch(userProfileByIdProvider(widget.userId));
    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;
    final isOwnProfile = currentUserId == widget.userId;
    final title = widget.type == 'following' ? 'Siguiendo' : 'Seguidores';

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const _FollowListLoadingShimmer(),
        error: (_, __) => const Center(child: Text("Error cargando perfil")),
        data: (profile) {
          // ✅ Usa el color REAL del avatar si la lista ya cargó; si no, fallback
          final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
          final dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : AllStatsView.getHeaderColor(profile, colors);

          final args = FollowListArgs(userId: widget.userId, type: widget.type);
          final usersState = ref.watch(followListProvider(args));

          return Stack(
            children: [
              // --- FONDO CON GRADIENTE DINÁMICO ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // ~40% del color dinámico para que se note
                      dynamicColor.withAlpha((255 * 0.40).round()),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),

              // --- CONTENIDO PRINCIPAL ---
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, colors, textTheme, title, dynamicColor),

                    Expanded(
                      child: usersState.when(
                        loading: () => const _FollowListLoadingShimmer(),
                        error: (_, __) =>
                            const Center(child: Text("Error cargando lista")),
                        data: (users) {
                          if (users.isEmpty) {
                            String emptyMessage;
                            if (widget.type == "following") {
                              emptyMessage = isOwnProfile
                                  ? "No sigues a nadie aún."
                                  : "${profile.nombrePerfil} no sigue a nadie.";
                            } else {
                              emptyMessage = isOwnProfile
                                  ? "No tienes seguidores todavía."
                                  : "${profile.nombrePerfil} no tiene seguidores todavía.";
                            }

                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/zorro_oops.png',
                                    width: 180,
                                    height: 180,
                                  ),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                    child: Text(
                                      emptyMessage,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return FadeInDown(
                            duration: const Duration(milliseconds: 400),
                            child: ListView.builder(
                              cacheExtent: 200.0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: users.length,
                              itemBuilder: (_, i) => FadeInDown(
                                duration: Duration(milliseconds: 300 + (i * 80)),
                                child: _FollowUserTile(
                                  key: ValueKey(users[i].userId),
                                  user: users[i],
                                  dynamicColor: dynamicColor,
                                  currentListArgs: args,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
    String title,
    Color dynamicColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .40), // was withOpacity(.4)
                shape: BoxShape.circle,
                border: Border.all(
                  // toque del color dinámico para integrarlo
                  color: dynamicColor.withAlpha((255 * 0.55).round()),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// Tarjeta de usuario
class _FollowUserTile extends ConsumerStatefulWidget {
  final FollowListModel user;
  final Color dynamicColor; // color del header (fallback)
  final FollowListArgs currentListArgs;

  const _FollowUserTile({
    super.key,
    required this.user,
    required this.dynamicColor,
    required this.currentListArgs,
  });

  @override
  ConsumerState<_FollowUserTile> createState() => _FollowUserTileState();
}

class _FollowUserTileState extends ConsumerState<_FollowUserTile>
    with TickerProviderStateMixin {
  late bool _isFollowing;
  bool _removed = false;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _isFollowing = widget.user.isFollowing;

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _popAnimation = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_FollowUserTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.isFollowing != widget.user.isFollowing) {
      setState(() {
        _isFollowing = widget.user.isFollowing;
      });
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool get _isCurrentUser {
    final current = ref.read(authStateProvider).value?.session?.user.id;
    return widget.user.userId == current;
  }

  bool get isFollowersView => widget.currentListArgs.type == "followers";
  bool get isFollowingView => widget.currentListArgs.type == "following";

  Future<void> _toggle() async {
    if (ref.read(followControllerProvider)) return;

    final old = _isFollowing;
    final currentUserId = ref.read(authStateProvider).value?.session?.user.id;
    final isMyFollowingList =
        isFollowingView && widget.currentListArgs.userId == currentUserId;

    if (isMyFollowingList && _isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Dejar de seguir"),
          content: Text("¿Quieres dejar de seguir a @${widget.user.nombreUsuario}?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí")),
          ],
        ),
      );

      if (confirm != true) return;

      await _slideController.forward();
      if (mounted) setState(() => _removed = true);
    }

    _popController.forward().then((_) => _popController.reverse());

    setState(() => _isFollowing = !_isFollowing);

    try {
      final result = await ref
          .read(followControllerProvider.notifier)
          .toggleFollow(widget.user.userId, currentListArgs: widget.currentListArgs);

      if (mounted) {
        setState(() => _isFollowing = result);
      }

      Future.microtask(() {
        ref.invalidate(followListProvider(widget.currentListArgs));
      });
    } catch (e) {
      if (mounted) setState(() => _isFollowing = old);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (_removed) return const SizedBox.shrink();

    // ✅ Colores/imagen por usuario (desde BD):
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    final String avatarPath = avatarsList.isNotEmpty
        ? getAvatarAssetPathById(widget.user.idAvatarSeleccionado, avatarsList)
        : '';

    // ✅ Color real del avatar del usuario de la fila; si no hay lista, usa el del header
    final Color tileColor = avatarsList.isNotEmpty
        ? getAvatarColorById(widget.user.idAvatarSeleccionado, avatarsList)
        : widget.dynamicColor;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: InkWell(
          onTap: _isCurrentUser ? null : () => context.push('/profile/${widget.user.userId}'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: .95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tileColor.withValues(alpha: .60)),
              boxShadow: [
                BoxShadow(
                  color: tileColor.withValues(alpha: .25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            tileColor.withValues(alpha: .80),
                            tileColor.withValues(alpha: .15),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    ClipOval(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: (avatarPath.isEmpty)
                            ? const ColoredBox(color: Colors.transparent)
                            : OptimizedImage(
                                imagePath: avatarPath,
                                fit: BoxFit.cover,
                                enableCache: true,
                                width: 48,
                                height: 48,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.nombrePerfil,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "@${widget.user.nombreUsuario}",
                        style: t.bodySmall?.copyWith(
                          color: c.onSurface.withValues(alpha: .60),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isCurrentUser)
                  ScaleTransition(
                    scale: _popAnimation,
                    child: GestureDetector(
                      onTap: _toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isFollowing ? c.surface : tileColor,
                          borderRadius: BorderRadius.circular(50),
                          border: _isFollowing ? Border.all(color: c.outlineVariant) : null,
                        ),
                        child: Text(
                          _isFollowing ? "Siguiendo" : "Seguir",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _isFollowing ? c.onSurface : c.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowListLoadingShimmer extends StatelessWidget {
  const _FollowListLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: c.surfaceContainerHigh,
      highlightColor: c.surfaceContainerHighest,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 120, height: 12, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          ],
        ),
      ),
    );
  }
}
