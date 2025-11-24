import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart'; // Fallback
import 'package:kitsucode/core/providers/retry_connection_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
// ✅ Importar helpers de avatar para el color correcto
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

/// Un widget genérico para mostrar cuando no hay conexión a Internet
class NoInternetView extends ConsumerStatefulWidget {
  const NoInternetView({super.key});

  @override
  ConsumerState<NoInternetView> createState() => _NoInternetViewState();
}

class _NoInternetViewState extends ConsumerState<NoInternetView> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return; // Prevenir múltiples clicks

    setState(() => _isRetrying = true);

    try {
      // Ejecutar la función de reintento que devuelve la ruta destino
      final retryFunction = ref.read(retryConnectionProvider);
      final destinationRoute = await retryFunction();

      // Si llegamos aquí, la conexión se recuperó
      if (mounted) {
        context.go(destinationRoute);
      }
    } catch (e) {
      // Si falla, mostramos el snackbar personalizado
      if (mounted) {
        showErrorSnackbar(
          context,
          'Sin conexión', 
          'No se pudo conectar. Revisa tu conexión e intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- Lógica para obtener el color dinámico ---
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;
    
    final profileState = (currentAuthUserId != null)
        ? ref.watch(userProfileByIdProvider(currentAuthUserId))
        : null;

    final profile = profileState?.asData?.value;

    // ✅ CORRECCIÓN: Obtener lista de avatares para el color real de la BD
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

    final Color dynamicColor;
    if (profile != null) {
      dynamicColor = avatarsList.isNotEmpty
          ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
          : AllStatsView.getHeaderColor(profile, colors); // Fallback
    } else {
      dynamicColor = colors.primary;
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          // --- CAPA DE FONDO ---
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

          // --- CAPA DE CONTENIDO ---
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. La imagen del zorro
                    Image.asset('assets/images/home/alerta.webp', width: 200),
                    const SizedBox(height: 24),

                    // 2. Mensaje de Título
                    Text(
                      '¡Oops! Sin conexión',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 3. Mensaje descriptivo
                    Text(
                      'Parece que no puedes conectarte. Revisa tu conexión a Internet y vuelve a intentarlo.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 4. Botón de Reintentar
                    _isRetrying
                        ? CircularProgressIndicator(color: dynamicColor)
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dynamicColor,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              textStyle: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _handleRetry,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}