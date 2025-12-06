import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/widgets/animated_stat_badge.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

class _StaggerItem extends StatefulWidget {
  final Widget child;
  final int delay;

  const _StaggerItem({required this.child, required this.delay});

  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

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

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId != null) {
        ref
            .read(languageCompletionProvider.notifier)
            .checkLanguageCompletion(userId);
      }
    });
  }

  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (langName.toLowerCase().trim()) {
      case 'python':
        return isDark ? AppThemes.pythonDarkTheme : AppThemes.pythonTheme;
      case 'c':
        return isDark ? AppThemes.cDarkTheme : AppThemes.cTheme;
      case 'java':
        return isDark ? AppThemes.javaDarkTheme : AppThemes.javaTheme;
      default:
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
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

  ColorScheme _adjustJavaColors(ColorScheme original) {
    final isDark = original.brightness == Brightness.dark;

    if (isDark) {
      return original.copyWith(
        primary: const Color(0xFFFF9A7F),
        primaryContainer: const Color(0xFFB85A40),
        primaryFixed: const Color(0xFFFFD6CC),
        secondary: const Color(0xFF5FD9CC),
        secondaryContainer: const Color(0xFF1F7A70),
        secondaryFixed: const Color(0xFFB8EDE7),
        tertiary: const Color(0xFFFFB77F),
        tertiaryContainer: const Color(0xFFB86A30),
      );
    } else {
      return original.copyWith(
        primary: const Color(0xFFE76F51),
        primaryContainer: const Color(0xFFFFE5DD),
        primaryFixed: const Color(0xFFFFD6CC),
        secondary: const Color(0xFF2A9D8F),
        secondaryContainer: const Color(0xFFCCF5F0),
        secondaryFixed: const Color(0xFFB8EDE7),
        tertiary: const Color(0xFFF4A261),
        tertiaryContainer: const Color(0xFFFFE8D6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBarRealtimeProvider);
    final stats = ref.watch(appBarProvider);

    final languageTheme = _getLanguageTheme(
      stats.languageName,
      Theme.of(context).brightness,
    );

    ref.listen<AppBarState>(appBarProvider, (previous, next) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (previous != null &&
          !previous.isLoading &&
          !next.isLoading &&
          previous.languageId != next.languageId) {
        showSuccessSnackbar(
          context,
          '¡Lenguaje Cambiado!',
          'Ahora estás en el mundo de ${next.languageName.toUpperCase()}.',
        );
      }
    });

    if (stats.isLoading) {
      return Theme(
        data: languageTheme,
        child: Container(
          height: widget.preferredSize.height,
          padding: const EdgeInsets.only(
            top: 40,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        ),
      );
    }

    final languageColor = _getColorForLanguage(stats.languageName);

    return Theme(
      data: languageTheme,
      child: Container(
        height: widget.preferredSize.height,
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLanguageSelector(context, ref, stats, languageTheme),
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
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppBarState stats,
    ThemeData languageTheme,
  ) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(audioControllerProvider).playClick();

              _portalController.hide();
              setState(() => _isMenuOpen = false);
            },
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.transparent)),
                CompositedTransformFollower(
                  link: _layerLink,
                  offset: const Offset(0, 52),
                  child: Material(
                    type: MaterialType.transparency,
                    child: IntrinsicWidth(
                      child: IntrinsicHeight(
                        child: GestureDetector(
                          onTap: () {},
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeInBack,
                            child: _isMenuOpen
                                ? _buildLanguageMenu(
                                    context,
                                    ref,
                                    stats.languageId,
                                    languageTheme,
                                  )
                                : const SizedBox.shrink(),
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
            HapticFeedback.lightImpact();
            ref.read(audioControllerProvider).playClick();

            setState(() => _isMenuOpen = !_isMenuOpen);
            _portalController.toggle();
          },
          child: AnimatedScale(
            scale: _isMenuOpen ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
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
      ),
    );
  }

  Widget _buildLanguageMenu(
    BuildContext context,
    WidgetRef ref,
    int currentLangId,
    ThemeData languageTheme,
  ) {
    final stats = ref.watch(appBarProvider);
    final isJava = stats.languageName.toLowerCase().trim() == 'java';

    var colorScheme = languageTheme.colorScheme;
    if (isJava) {
      colorScheme = _adjustJavaColors(colorScheme);
    }

    final textTheme = languageTheme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final languageListAsync = ref.watch(languageListProvider);

    return languageListAsync.when(
      error: (e, st) => _errorBox(colorScheme),
      loading: () => _loadingBox(colorScheme),
      data: (allLangs) {
        final otherLangs = allLangs
            .where((lang) => lang['id_lenguaje'] != currentLangId)
            .toList();

        final items = otherLangs.map((lang) {
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

        final List<Color> panelGradientColors = isDark
            ? [
                colorScheme.primaryContainer.withOpacity(0.90),
                colorScheme.tertiaryContainer.withOpacity(0.90),
              ]
            : [
                colorScheme.primaryFixed.withOpacity(0.90),
                colorScheme.secondaryFixed.withOpacity(0.90),
              ];

        final Color panelBorderColor = colorScheme.primary;

        final List<BoxShadow> panelShadows = [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ];

        return Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: panelGradientColors,
                  ),
                  border: Border.all(color: panelBorderColor, width: 3.0),
                  boxShadow: panelShadows,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(items.length, (i) {
                    return _StaggerItem(delay: i * 70, child: items[i]);
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _errorBox(ColorScheme colorScheme) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "Error al cargar lenguajes.",
          style: TextStyle(color: colorScheme.onError),
        ),
      ),
    );
  }

  Widget _loadingBox(ColorScheme colorScheme) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildLanguageMenuItem(
    String langName,
    String langAsset,
    int langId,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final languageState = ref.watch(languageCompletionProvider);
    final unlockedLanguages = languageState.unlockedLanguages;

    final normalizedLangName = langName.trim().toLowerCase();
    final normalizedUnlocked = unlockedLanguages
        .map((l) => l.trim().toLowerCase())
        .toList();

    final isCompleted = normalizedUnlocked.contains(normalizedLangName);
    final isDark = colorScheme.brightness == Brightness.dark;

    final List<Color> itemGradientColors = isDark
        ? [
            colorScheme.primaryContainer.withOpacity(0.85),
            colorScheme.secondaryContainer.withOpacity(0.85),
          ]
        : [
            colorScheme.primaryFixed.withOpacity(0.85),
            colorScheme.secondaryFixed.withOpacity(0.85),
          ];
    final Color itemBorderColor = isDark
        ? colorScheme.primaryFixed
        : colorScheme.secondaryFixedDim;

    final Color titleColor = isDark
        ? colorScheme.onSurface
        : colorScheme.onPrimaryFixedVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        _portalController.hide();
        setState(() => _isMenuOpen = false);

        if (!isCompleted) {
          HapticFeedback.heavyImpact();
          ref.read(audioControllerProvider).playError();

          showWarningSnackbar(
            context,
            '¡Aún no!',
            'No puedes cambiar de lenguaje hasta terminar el actual.',
          );
          return;
        }

        HapticFeedback.mediumImpact();
        ref.read(audioControllerProvider).playClick();

        try {
          final userId = ref.read(authStateProvider).value?.session?.user.id;
          if (userId == null) throw Exception("Usuario no autenticado");

          await ref
              .read(languageCompletionProvider.notifier)
              .updateFavoriteLanguage(userId, normalizedLangName);

          await ref
              .read(languageCompletionProvider.notifier)
              .checkLanguageCompletion(userId);

          await ref.read(appBarProvider.notifier).fetchStats();
        } catch (e) {
          if (!mounted) return;

          ref.read(audioControllerProvider).playError();

          showErrorSnackbar(
            context,
            '¡Error!',
            'No se pudo cambiar de lenguaje: ${e.toString()}',
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: itemGradientColors,
          ),
          border: Border.all(color: itemBorderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.18),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(230),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(langAsset),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                langName.toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (isCompleted)
              Icon(Icons.check_circle, color: Colors.green.shade300, size: 22)
            else
              Icon(
                Icons.lock,
                color: colorScheme.onPrimary.withOpacity(0.55),
                size: 20,
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
                  blurRadius: 2,
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
