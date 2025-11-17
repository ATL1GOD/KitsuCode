// lib/shared/appbar/kitsu_appbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/widgets/animated_stat_badge.dart';
// 🆕 NUEVO: Importar providers necesarios
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // 🔥 NUEVO: Verificar lenguajes completados al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId != null) {
        ref.read(languageCompletionProvider.notifier).checkLanguageCompletion(userId);
      }
    });
  }

  String _getAssetForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/home/logo_python.webp';
      case 'java':
        return 'assets/images/home/logo_java.webp';
      case 'c':
        return 'assets/images/home/logo_c.webp';
      default:
        return 'assets/images/home/logo_python.webp';
    }
  }

  Color _getColorForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return const Color(0xFF19647E);
      case 'java':
        return const Color(0xFFB31900);
      case 'c':
        return const Color(0xFF004D92);
      default:
        return const Color(0xFF19647E);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBarRealtimeProvider);
    final stats = ref.watch(appBarProvider);

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
            borderColor: languageColor,
          ),
          AnimatedStatBadge(
            value: stats.trophies,
            icon: Icons.emoji_events,
            color: Colors.amber,
            type: StatType.trophy,
            borderColor: languageColor,
          ),
          AnimatedStatBadge(
            value: stats.lives,
            icon: Icons.favorite,
            color: Colors.red,
            type: StatType.life,
            borderColor: languageColor,
          ),
        ],
      ),
    );
  }

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
            offset: const Offset(0, 52.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: _buildLanguageMenu(context, ref, stats.languageId),
            ),
          );
        },
        child: InkWell(
          onTap: () async {
            // 🔥 NUEVO: Verificar lenguajes antes de abrir el menú
            final userId = ref.read(authStateProvider).value?.session?.user.id;
            if (userId != null) {
              await ref.read(languageCompletionProvider.notifier)
                  .checkLanguageCompletion(userId);
            }
            
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
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                border: Border.all(
                  color: colorScheme.primaryContainer,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
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

  Future<List<Map<String, dynamic>>> _fetchLanguages(int currentLangId) async {
    final supabase = Supabase.instance.client;
    final langs = await supabase.from('lenguaje').select();
    final otherLangs = langs.where((lang) {
      return lang['id_lenguaje'] != currentLangId;
    }).toList();
    return otherLangs;
  }

  // 🔥 MÉTODO CORREGIDO - Ahora verifica si el lenguaje está completado
  Widget _buildLanguageMenuItem(
    String langName,
    String langAsset,
    int langId,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    // Obtener el estado de los lenguajes completados
    final languageState = ref.watch(languageCompletionProvider);
    final unlockedLanguages = languageState.unlockedLanguages;
    
    // Normalizar el nombre del lenguaje para comparar
    final normalizedLangName = langName.trim().toLowerCase();
    final normalizedUnlocked = unlockedLanguages
        .map((l) => l.trim().toLowerCase())
        .toList();
    
    // Verificar si este lenguaje está completado
    final isCompleted = normalizedUnlocked.contains(normalizedLangName);

    return InkWell(
      onTap: () async {
        _portalController.hide();
        
        // ✅ LÓGICA CORREGIDA
        if (!isCompleted) {
          // 🔒 Lenguaje NO completado - Mostrar error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Debes completar ${langName.toUpperCase()} primero"
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
        
        // ✅ Lenguaje completado - Permitir cambio
        try {
          final userId = ref.read(authStateProvider).value?.session?.user.id;
          if (userId == null) {
            throw Exception('Usuario no autenticado');
          }

          // Cambiar el lenguaje
          await ref.read(languageCompletionProvider.notifier)
              .updateFavoriteLanguage(userId, normalizedLangName);

          // 🔥 CRÍTICO: Volver a verificar lenguajes completados
          // Esto actualiza la lista de unlockedLanguages
          await ref.read(languageCompletionProvider.notifier)
              .checkLanguageCompletion(userId);

          // Actualizar el appBar
          await ref.read(appBarProvider.notifier).fetchStats();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cambiado a ${langName.toUpperCase()}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar del lenguaje
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
            
            // Nombre del lenguaje
            Expanded(
              child: Text(
                langName.toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Ícono de estado
            if (isCompleted)
              Icon(
                Icons.check_circle,
                color: Colors.green.shade300,
                size: 20,
              )
            else
              Icon(
                Icons.lock,
                color: colorScheme.onPrimary.withValues(alpha: 0.5),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
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