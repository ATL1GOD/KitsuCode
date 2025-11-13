import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/provider/follow_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';

// --- NUEVO: Mapa de IDs de Lenguaje a sus assets ---
// Basado en el JSON que me diste: [{"id_lenguaje":1,"nombre":"c"}, ...]
// ¡Asegúrate de que estas rutas de assets sean correctas!
const Map<int, String> _languageAssets = {
  1: 'assets/images/logo_c.png',
  2: 'assets/images/logo_java.png', // <-- Corregí una errata (decía assetss)
  3: 'assets/images/logo_python.png',
};

/// Devuelve un color específico basado en el string del rango.
Color _getRankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'diamante':
      return const Color(0xFFb9f2ff); // Azul Diamante
    case 'oro':
      return const Color(0xFFFFD700); // Oro (Dorado)
    case 'plata':
      return const Color(0xFFC0C0C0); // Plata
    case 'bronce':
      return const Color(0xFFCD7F32); // Bronce
    default:
      return Colors.grey.shade500;
  }
}

// --- ¡NUEVO! ---
/// Devuelve un IconData específico basado en el string del rango.
/// ¡Puedes cambiar estos iconos por los que prefieras!
IconData _getRankIcon(String rank) {
  switch (rank.toLowerCase()) {
    case 'diamante':
      return Icons.diamond_outlined; // Icono de diamante
    case 'oro':
      return Icons.emoji_events_outlined; // Icono de trofeo
    case 'plata':
      return Icons.shield_outlined; // Icono de escudo
    case 'bronce':
      return Icons.star_border_outlined; // Icono de estrella
    default:
      return Icons.bookmark_border; // Un icono por defecto
  }
}
// --- FIN NUEVO ---

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
    final rankIcon = _getRankIcon(rank); // <-- ¡NUEVO! Obtenemos el icono

    // --- ¡CAMBIO! Construye la LISTA de iconos ---
    List<Widget> languageIcons = [];
    if (rankLanguageIds != null && rankLanguageIds!.isNotEmpty) {
      for (var langId in rankLanguageIds!) {
        if (_languageAssets.containsKey(langId)) {
          languageIcons.add(
            Padding(
              // Separación entre iconos
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Image.asset(
                _languageAssets[langId]!,
                width: 20, // <-- ¡MÁS PEQUEÑO!
                height: 20, // <-- ¡MÁS PEQUEÑO!
              ),
            ),
          );
        }
      }
    }
    // --- FIN CAMBIO ---

    return ZoomIn(
      duration: const Duration(milliseconds: 300),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: userProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildErrorCard(colors, err),
          data: (user) {
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
                    border: Border.all(
                      color: rankColor.withAlpha(204), // 0.8 opacity
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withAlpha(128), // 0.5 opacity
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
                                  context,
                                  user.siguiendoCount.toString(),
                                  'Siguiendo'),
                              _buildStatColumn(
                                  context,
                                  user.seguidoresCount.toString(),
                                  'Seguidores'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FollowButton(userId: userId),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                context.pop(); // Cierra el modal
                                context.push(
                                    '/profile/${user.userId}'); // Navega al perfil del usuario
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primary,
                                side: BorderSide(
                                    color: colors.primary.withAlpha(128)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30), // Bordes más redondeados
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
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: AssetImage(
                        getAvatarAssetPathById(user.idAvatarSeleccionado),
                      ),
                      backgroundColor: colors.surfaceContainer,
                    ),
                  ),
                ),
                
                // --- ¡CAMBIO! Badge de Rango (Superior Derecha) ---
                Positioned(
                  top: 70, // 60 (margen) + 10
                  right: 15, // En la esquina derecha
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColor, // Color de fondo del rango
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: colors.surface, width: 1.5), // Borde blanco
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38), // 0.15 opacity
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    // ¡CAMBIO! Reemplazamos el Text por un Row
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ¡NUEVO! El icono del rango
                        Icon(
                          rankIcon,
                          color: Colors.black, // Color del icono
                          size: 14, // Tamaño pequeño, ajusta si es necesario
                        ),
                        const SizedBox(width: 4), // Un pequeño espacio
                        // El texto original
                        Text(
                          rank[0].toUpperCase() +
                              rank.substring(1).toLowerCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- FIN CAMBIO ---

                // --- ¡CAMBIO! Iconos de Lenguaje (Superior Izquierda) ---
                if (languageIcons.isNotEmpty)
                  Positioned(
                    top: 70, // Misma altura que el badge de rango
                    left: 15, // En la esquina izquierda
                    child: Container(
                      // Limita el ancho en caso de que haya DEMASIADOS iconos
                      constraints: const BoxConstraints(maxWidth: 100),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: rankColor, // Color de fondo del rango
                        borderRadius:
                            BorderRadius.circular(20), // Forma de "píldora"
                        border: Border.all(
                            color: colors.surface, width: 1.5), // Borde blanco
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38), // 0.15 opacity
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      // Usamos una Fila para poner los iconos uno al lado del otro
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: languageIcons, // <-- La lista de iconos
                      ),
                    ),
                  ),
                // --- FIN CAMBIO ---
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme colors, Object err) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 48),
          const SizedBox(height: 16),
          Text('Error al cargar el perfil',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.error),
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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class FollowButton extends ConsumerWidget {
  final String userId;
  const FollowButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isFollowingState = ref.watch(isFollowingProvider(userId));
    final isLoading = ref.watch(followControllerProvider);

    return SizedBox(
      width: double.infinity,
      child: isFollowingState.when(
        data: (isFollowing) {
          return ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    ref
                        .read(followControllerProvider.notifier)
                        .toggleFollow(userId);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? colors.surfaceContainerHighest
                  : colors.primary,
              foregroundColor:
                  isFollowing ? colors.onSurfaceVariant : colors.onPrimary,
              padding:
                  const EdgeInsets.symmetric(vertical: 13), // Aumentamos la altura
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(30), // Bordes más redondeados
              ),
              elevation: 2, // Le damos una pequeña sombra
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isFollowing ? 'Siguiendo' : 'Seguir',
                      key: ValueKey(isFollowing)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            ElevatedButton(onPressed: null, child: const Text('Error')),
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
      CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(BuildContext context, String assetPath,
      Animation<Alignment> animation, double size) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Align(alignment: animation.value, child: child),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: colors.primary.withAlpha(26),
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
          _buildIcon(
              context, 'assets/images/logo_python.png', _animations[0], 50),
          _buildIcon(
              context, 'assets/images/logo_java.png', _animations[1], 60),
          _buildIcon(context, 'assets/images/logo_c.png', _animations[2], 70),
          _buildIcon(
              context, 'assets/images/logo_python.png', _animations[3], 40),
          _buildIcon(
              context, 'assets/images/logo_java.png', _animations[4], 55),
        ],
      ),
    );
  }
}