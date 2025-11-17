import 'package'
    ':flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/widgets/animated_stat_badge.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

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
    //Verificar lenguajes completados al cargar
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

    // Escuchamos el provider de la AppBar para reaccionar a los cambios
    ref.listen<AppBarState>(appBarProvider, (previous, next) {
      
      // Verificamos si hay un estado previo, si no estamos cargando,
      // y si el ID del lenguaje realmente cambió.
      if (previous != null &&
          !previous.isLoading &&
          !next.isLoading &&
          previous.languageId != next.languageId) {
            
        // ¡El estado cambió con éxito!
        // Usamos el 'context' estable del 'build' de la AppBar
        showSuccessSnackbar(
          context,
          '¡Lenguaje Cambiado!',
          'Ahora estás en el mundo de ${next.languageName.toUpperCase()}.',
        );
      }
    });
    // fin del ref.listen

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
          return GestureDetector(
            onTap: () {
              // Cierra al hacer clic en cualquier lugar fuera del menú
              _portalController.hide();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.transparent), // El barrier transparente
                ),
                CompositedTransformFollower(
                  link: _layerLink,
                  offset: const Offset(0, 52.0),
                  child: Material( // IMPORTANTE: Agregamos Material aquí para que el Stack interno se renderice correctamente
                    type: MaterialType.transparency,
                    child: Align(
                      alignment: Alignment.topLeft,
                      // Envolvemos el menú en un ConstrainedBox o IntrinsicWidth/Height
                      // para asegurar que el menú no intente ocupar todo el espacio vertical.
                      child: IntrinsicWidth( // Esto le dice al Column que use el tamaño intrínseco de sus hijos
                        child: IntrinsicHeight( // Limita la altura a la de sus hijos también
                          child: GestureDetector(
                            onTap: () {
                              // Absorbe el clic para que no cierre el menú si se pulsa en la lista
                            },
                            child: _buildLanguageMenu(context, ref, stats.languageId),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

Widget _buildLanguageMenu(
    BuildContext context,
    WidgetRef ref,
    int currentLangId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    //Estamos observando el provider (Pre-fetch).
    final languageListAsync = ref.watch(languageListProvider);

    //REEMPLAZAMOS el FutureBuilder por languageListAsync.when
    return languageListAsync.when(
      // 1. Caso de Error
      error: (e, st) {
        return Material(
          type: MaterialType.transparency,
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text("Error al cargar lenguajes.", style: TextStyle(color: colorScheme.onError)),
          ),
        );
      },
      // 2. Caso de Carga (Sólo si es la primera vez que se accede)
      loading: () {
        return Material(
          type: MaterialType.transparency,
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      // 3. Caso de Datos Listos (¡Lo que se ejecutará instantáneamente si ya cargó!)
      data: (allLangs) {
        // Filtramos la lista ya cargada en memoria, OMITIENDO el lenguaje actual.
        final otherLangs = allLangs.where((lang) {
          return lang['id_lenguaje'] != currentLangId;
        }).toList();

        final children = otherLangs.map((lang) {
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

        return Material(
          type: MaterialType.transparency,
          child: Container(
            key: const ValueKey('menu_loaded'), // Mantenemos el key para AnimatedSwitcher
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

  //Ahora verifica si el lenguaje está completado
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
        
        // Capturamos el context ANTES de los await
        final stableContext = context; 
        
        // Lógica de restricción (sin cambios)
        if (!isCompleted) {
          if (mounted) {
            showWarningSnackbar(stableContext, '¡Aún no!', 'No puedes cambiar de lenguaje hasta terminar el actual.');
          }
          return;
        }
        
        // Lenguaje completado - Permitir cambio
        try {
          final userId = ref.read(authStateProvider).value?.session?.user.id;
          if (userId == null) {
            throw Exception('Usuario no autenticado');
          }

          // 1. Cambiar el lenguaje
          await ref.read(languageCompletionProvider.notifier).updateFavoriteLanguage(userId, normalizedLangName);

          // 2. Volver a verificar y actualizar AppBar
          await ref.read(languageCompletionProvider.notifier).checkLanguageCompletion(userId);
          await ref.read(appBarProvider.notifier).fetchStats();       
          
        } catch (e) {
          if (mounted) {
            showErrorSnackbar(stableContext, '¡Error!', 'No se pudo cambiar de lenguaje: ${e.toString()}');
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
                // Corregido el 'withOpacity' obsoleto
                color: colorScheme.onPrimary.withAlpha((255 * 0.5).round()), 
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