import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

/// Widget reutilizable para el fondo animado de las vistas de Settings
/// La animación Lottie se oculta mediante un fade out/colapso cuando se
/// abre el teclado virtual para optimizar el rendimiento del formulario.
class AnimatedSettingsBackground extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dynamicColor = AllStatsView.getHeaderColor(profile, colors);
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
                  dynamicColor.withAlpha(100),
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          // --- ANIMACIÓN LOTTIE CONTROLADA (Usa AnimatedOpacity) ---
          AnimatedOpacity( // <-- ANIMACIÓN PARA OCULTAR
            opacity: isKeyboardVisible ? 0.0 : 0.85, // Si el teclado está visible, opacidad 0
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                colors.secondaryFixedDim.withAlpha((255 * 0.8).round()),
                BlendMode.srcIn,
              ),
              child: RepaintBoundary(
                child: Lottie.asset(
                  'assets/animations/spring.json',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  repeat: true,
                  frameRate: FrameRate.max,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}