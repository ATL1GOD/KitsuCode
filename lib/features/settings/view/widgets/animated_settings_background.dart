import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

/// Widget reutilizable para el fondo animado de las vistas de Settings
/// 
/// Mantiene la animación Lottie activa usando [RepaintBoundary] para 
/// optimizar el rendimiento y evitar "freezes" al navegar entre sub-vistas.
class AnimatedSettingsBackground extends StatelessWidget {
  final UserProfileModel profile;
  final ColorScheme colors;

  const AnimatedSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
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
          
          // --- ANIMACIÓN LOTTIE OPTIMIZADA ---
          Opacity(
            opacity: 0.85, // Ligeramente más transparente para reducir carga visual
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
                  // Renderiza frames más espaciados para mejor performance
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
