import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

// ✅ añadidos para obtener el color desde la BD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

/// Widget reutilizable para el fondo animado de Settings.
/// La animación Lottie se oculta (fade) y se desmonta cuando se abre el teclado
/// para optimizar el rendimiento.
class AnimatedSettingsBackground extends ConsumerWidget {
  final UserProfileModel profile;
  final ColorScheme colors;
  final bool isKeyboardVisible; // <-- NUEVA PROPIEDAD

  const AnimatedSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
    required this.isKeyboardVisible, // <-- REQUERIDO
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Color primario desde BD (avatar) — mismo método usado en otras vistas
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    final int avatarId = profile.idAvatarSeleccionado;

    final dynamicColor = avatarsList.isNotEmpty
        ? getAvatarColorById(avatarId, avatarsList)
        : AllStatsView.getHeaderColor(profile, colors);

    return RepaintBoundary(
      child: Stack(
        children: [
          // --- FONDO DEGRADADO ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // alineado al resto de pantallas (~40% de opacidad)
                  dynamicColor.withAlpha((255 * 0.4).round()),
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          // --- ANIMACIÓN LOTTIE CONTROLADA ---
          // 1) Visibility desmonta el child cuando hay teclado (ahorro real de recursos)
          // 2) AnimatedOpacity mantiene el fade suave
          Visibility(
            visible: !isKeyboardVisible,
            maintainState: false,
            child: AnimatedOpacity(
              opacity: isKeyboardVisible ? 0.0 : 0.85,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.secondaryFixedDim.withAlpha((255 * 0.8).round()),
                  BlendMode.srcIn,
                ),
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Lottie.asset(
                      'assets/animations/spring.json',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      repeat: true,
                      frameRate: FrameRate(30), // Optimizado: 30fps
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
