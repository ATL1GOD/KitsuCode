import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/provider/follow_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

// --- Íconos de lenguajes (assets locales) ---
const Map<int, String> _languageAssets = {
  1: 'assets/images/logo_c.png',
  2: 'assets/images/logo_java.png',
  3: 'assets/images/logo_python.png',
};

Color _getRankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'diamante':
      return const Color(0xFFb9f2ff);
    case 'oro':
      return const Color(0xFFFFD700);
    case 'plata':
      return const Color(0xFFC0C0C0);
    case 'bronce':
      return const Color(0xFFCD7F32);
    default:
      return Colors.grey.shade500;
  }
}

IconData _getRankIcon(String rank) {
  switch (rank.toLowerCase()) {
    case 'diamante':
      return Icons.diamond_outlined;
    case 'oro':
      return Icons.emoji_events_outlined;
    case 'plata':
      return Icons.shield_outlined;
    case 'bronce':
      return Icons.star_border_outlined;
    default:
      return Icons.bookmark_border;
  }
}

/// Renderiza imágenes:
/// - `assets/...` -> Image.asset
/// - URL / ruta remota -> OptimizedImage
Widget _smartImage({
  required String path,
  required double width,
  required double height,
  BoxFit fit = BoxFit.cover,
}) {
  if (path.isEmpty) {
    return const ColoredBox(color: Colors.transparent);
  }
  if (path.startsWith('assets/')) {
    return Image.asset(path, width: width, height: height, fit: fit);
  }
  return OptimizedImage(
    imagePath: path,
    width: width,
    height: height,
    fit: fit,
    enableCache: true,
  );
}

class UserProfileModal extends ConsumerWidget {
  final String userId;
  final String rank;
  final List<int>? rankLanguageIds;

  const UserProfileModal({
    super.key,
    required this.userId,
    required this.rank,
    this.rankLanguageIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileByIdProvider(userId));
    final rankColor = _getRankColor(rank);
    final rankIcon = _getRankIcon(rank);

    // Para resolver correctamente rutas de avatares (assets/URL)
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

    // Íconos de lenguajes (assets locales)
    final List<Widget> languageIcons = [
      if (rankLanguageIds != null)
        for (final id in rankLanguageIds!)
          if (_languageAssets[id] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Image.asset(
                _languageAssets[id]!,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
    ];

    return ZoomIn(
      duration: const Duration(milliseconds: 300),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: userProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildErrorCard(colors, err),
          data: (user) {
            // Ruta final del avatar (puede ser asset o URL)
            final String avatarPath = getAvatarAssetPathById(
              user.idAvatarSeleccionado,
              avatarsList, // <--- IMPORTANTE
            );

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 60),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: rankColor.withAlpha(204), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withAlpha(128),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _DecorativeBackground()),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user.nombrePerfil,
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text('@${user.nombreUsuario}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                  context, user.siguiendoCount.toString(), 'Siguiendo'),
                              _buildStatColumn(
                                  context, user.seguidoresCount.toString(), 'Seguidores'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FollowButton(userId: userId),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                context.pop();
                                context.push('/profile/${user.userId}');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primary,
                                side: BorderSide(color: colors.primary.withAlpha(128)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Ver Perfil'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Avatar grande (usa helper inteligente)
                Positioned(
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withAlpha(100),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: _smartImage(
                          path: avatarPath,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge de rango
                Positioned(
                  top: 70,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.surface, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rankIcon, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rank[0].toUpperCase() + rank.substring(1).toLowerCase(),
                          style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lenguajes (assets locales)
                if (languageIcons.isNotEmpty)
                  Positioned(
                    top: 70,
                    left: 15,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: rankColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.surface, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: languageIcons),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme colors, Object err) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 48),
          const SizedBox(height: 16),
          Text('Error al cargar el perfil',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: colors.error),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(err.toString(),
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}

class FollowButton extends ConsumerWidget {
  final String userId;
  const FollowButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    final isFollowingState = ref.watch(isFollowingProvider(userId));
    final isLoading = ref.watch(followControllerProvider);

    return SizedBox(
      width: double.infinity,
      child: isFollowingState.when(
        data: (isFollowing) => ElevatedButton(
          onPressed: isLoading
              ? null
              : () => ref.read(followControllerProvider.notifier).toggleFollow(userId),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? c.surfaceContainerHighest : c.primary,
            foregroundColor: isFollowing ? c.onSurfaceVariant : c.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 13),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isFollowing ? 'Siguiendo' : 'Seguir',
                    key: ValueKey(isFollowing)),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ElevatedButton(onPressed: null, child: const Text('Error')),
      ),
    );
  }
}

class _DecorativeBackground extends StatefulWidget {
  const _DecorativeBackground();
  @override
  State<_DecorativeBackground> createState() => _DecorativeBackgroundState();
}

class _DecorativeBackgroundState extends State<_DecorativeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<Alignment>> _animations;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
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
  CurvedAnimation _createCurve(double begin, double end) =>
      CurvedAnimation(parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(
      BuildContext context, String assetPath, Animation<Alignment> anim, double size) {
    final c = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Align(alignment: anim.value, child: child),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: c.primary.withAlpha(26),
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          _buildIcon(context, 'assets/images/logo_python.png', _animations[0], 50),
          _buildIcon(context, 'assets/images/logo_java.png', _animations[1], 60),
          _buildIcon(context, 'assets/images/logo_c.png', _animations[2], 70),
          _buildIcon(context, 'assets/images/logo_python.png', _animations[3], 40),
          _buildIcon(context, 'assets/images/logo_java.png', _animations[4], 55),
        ],
      ),
    );
  }
}
