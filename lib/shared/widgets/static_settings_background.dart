import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

/// Widget de fondo estático para vistas de configuración.
/// 
/// Mantiene el degradado de color dinámico del perfil, pero sin
/// animaciones Lottie ni lógica de detección de teclado para máxima optimización.
class StaticSettingsBackground extends StatelessWidget {
  final UserProfileModel profile;
  final ColorScheme colors;

  const StaticSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos el color base del avatar para el degradado
    final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

    return Container(
      // Ya no es necesario RepaintBoundary, ya que no hay animación pesada.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // Degradado sutil basado en el color dinámico
            dynamicColor.withAlpha(100),
            colors.surfaceContainerLowest,
          ],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}