import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

// ✅ añadidos para obtener el color desde la BD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

/// Widget de fondo estático para vistas de configuración.
///
/// Mantiene el degradado de color dinámico del perfil, pero sin
/// animaciones Lottie ni lógica de detección de teclado para máxima optimización.
class StaticSettingsBackground extends ConsumerWidget {
  final UserProfileModel profile;
  final ColorScheme colors;

  const StaticSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Intentar obtener el color real desde la BD (lista de avatares)
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    final int avatarId = profile.idAvatarSeleccionado;

    // ✅ Si tenemos la lista, usamos el color_primario de la BD; si no, fallback al método previo
    final dynamicColor = avatarsList.isNotEmpty
        ? getAvatarColorById(avatarId, avatarsList)
        : AllStatsView.getHeaderColor(profile, colors);

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
