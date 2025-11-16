// lib/shared/appbar/kitsu_appbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/widgets/animated_stat_badge.dart';

// Sigue siendo un StatefulWidget para el OverlayPortal
class KitsuAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const KitsuAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  ConsumerState<KitsuAppBar> createState() => _KitsuAppBarState();
}

class _KitsuAppBarState extends ConsumerState<KitsuAppBar> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  // Helper de asset (Corregido a 'c')
  String _getAssetForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/home/logo_python.webp';
      case 'java':
        return 'assets/images/home/logo_java.webp';
      case 'c': // <-- Tu corrección
        return 'assets/images/home/logo_c.webp';
      default:
        return 'assets/images/home/logo_python.webp';
    }
  }

  // Helper para obtener el color primario del lenguaje
  Color _getColorForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return const Color(0xFF19647E); // Azul de Python
      case 'java':
        return const Color(0xFFB31900); // Rojo de Java
      case 'c':
        return const Color(0xFF004D92); // Azul de C
      default:
        return const Color(0xFF19647E); // Default Python
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBarRealtimeProvider);
    final stats = ref.watch(appBarProvider);

    // Loader (sin cambios)
    if (stats.isLoading) {
      return Container(
        height: widget.preferredSize.height,
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 22, backgroundColor: Colors.white24),
            _buildStatItem(
              icon: Icons.local_fire_department,
              color: Colors.grey,
              text: "...",
            ),
            _buildStatItem(
              icon: Icons.emoji_events,
              color: Colors.grey,
              text: "...",
            ),
            _buildStatItem(
              icon: Icons.favorite,
              color: Colors.grey,
              text: "...",
            ),
          ],
        ),
      );
    }

    // Contenido Real
    final languageColor = _getColorForLanguage(stats.languageName);

    return Container(
      height: widget.preferredSize.height,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLanguageSelector(context, ref, stats),
          AnimatedStatBadge(
            value: stats.streak,
            icon: Icons.local_fire_department,
            color: Colors.orange,
            type: StatType.streak,
            borderColor: languageColor, // Color del lenguaje
          ),

          AnimatedStatBadge(
            value: stats.trophies,
            icon: Icons.emoji_events,
            color: Colors.amber,
            type: StatType.trophy,
            borderColor: languageColor, // Color del lenguaje
          ),

          AnimatedStatBadge(
            value: stats.lives,
            icon: Icons.favorite,
            color: Colors.red,
            type: StatType.life,
            borderColor: languageColor, // Color del lenguaje
          ),
        ],
      ),
    );
  }

  /// El OverlayPortal (sin cambios en la lógica, solo el 'builder')
  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppBarState stats,
  ) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 52.0), // 44px avatar + 8px espacio
            child: Align(
              alignment: Alignment.topLeft,
              // Construimos el NUEVO menú "cool"
              child: _buildLanguageMenu(context, ref, stats.languageId),
            ),
          );
        },
        child: InkWell(
          onTap: () {
            _portalController.toggle();
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade400,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(stats.languageAssetPath),
            ),
          ),
        ),
      ),
    );
  }

  /// --- ¡CAMBIO DE ESTÉTICA! ---
  /// Este es el NUEVO menú "cool"
  Widget _buildLanguageMenu(
    BuildContext context,
    WidgetRef ref,
    int currentLangId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLanguages(currentLangId),
      builder: (context, snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          children = snapshot.data!.map((lang) {
            final langName = lang['nombre'] as String;
            final langAsset = _getAssetForLanguage(langName);
            final langId = lang['id_lenguaje'] as int;

            // --- CAMBIO DE ESTÉTICA (Items) ---
            // Le quitamos el fondo de "píldora" que tenía cada item
            return _buildLanguageMenuItem(
              langName,
              langAsset,
              langId,
              textTheme,
              colorScheme,
            );
          }).toList();
        } else if (snapshot.hasError) {
          children = [
            Text("Error", style: TextStyle(color: colorScheme.onError)),
          ];
        } else {
          children = [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        // --- ESTA ES LA ESTÉTICA "COOL" / VIDEOJUEGO ---
        return Material(
          type: MaterialType.transparency,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(snapshot.connectionState),
              width: 250,
              padding: const EdgeInsets.all(8.0), // Padding interno
              decoration: BoxDecoration(
                // 1. Color de fondo de 'utils' (¡SÓLIDO!)
                color: colorScheme.primary, // <-- El color de tu tema
                // 2. Borde de 'utils' (un tono más claro)
                border: Border.all(
                  color: colorScheme.primaryContainer, // Color claro del tema
                  width: 2.0,
                ),
                // 3. Bordes redondeados
                borderRadius: BorderRadius.circular(16.0),
                // 4. Sombra para profundidad
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20.0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper para el FutureBuilder (sin cambios)
  Future<List<Map<String, dynamic>>> _fetchLanguages(int currentLangId) async {
    final supabase = Supabase.instance.client;
    final langs = await supabase.from('lenguaje').select();
    final otherLangs = langs.where((lang) {
      return lang['id_lenguaje'] != currentLangId;
    }).toList();
    return otherLangs;
  }

  // --- CAMBIO DE ESTÉTICA ---
  // El item ahora es más simple, sin fondo propio
  Widget _buildLanguageMenuItem(
    String langName,
    String langAsset,
    int langId,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        _portalController.hide(); // Oculta el menú
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes terminar este lenguaje antes de cambiar"),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Más padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // ¡Alineación!
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(langAsset),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              langName,
              style: textTheme.bodyMedium?.copyWith(
                // --- CAMBIO: Color de texto de 'utils' ---
                // 'onPrimary' es el color para poner ENCIMA de 'primary'
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget reutilizable para CADA estadística (sin cambios)
  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    // ... (tu código sin cambios) ...
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(64),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black54,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
