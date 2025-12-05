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

    // --- LÓGICA BLINDADA PARA EL COLOR ---
    // Usamos un valor por defecto seguro para evitar la pantalla roja
    Color dynamicColor = colors.primary;

    try {
      // 1. Intentamos obtener el usuario actual de forma segura
      // Usamos .valueOrNull para que no lance excepción si está cargando o falla
      final authState = ref.watch(authStateProvider).valueOrNull;
      final currentAuthUserId = authState?.session?.user.id;

      if (currentAuthUserId != null) {
        // 2. Intentamos leer el perfil
        // Importante: .asData?.value evita que el error se propague si el provider falló
        final profileState = ref.watch(
          userProfileByIdProvider(currentAuthUserId),
        );
        final profile = profileState.asData?.value;

        // 3. Intentamos leer los avatares
        final avatarsState = ref.watch(currentUserAvatarsProvider);
        final avatarsList = avatarsState.asData?.value ?? [];

        if (profile != null) {
          dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : AllStatsView.getHeaderColor(profile, colors);
        }
      }
    } catch (e) {
      // Si algo falla al intentar obtener el color (común cuando no hay internet
      // y los providers lanzan excepciones), simplemente ignoramos el error
      // y usamos el color por defecto (colors.primary) definido arriba.
      // Esto previene la "Red Screen of Death" en el Onboarding.
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
                    Image.asset(
                      'assets/images/home/alerta.webp',
                      width: 200,
                      cacheWidth: 400,
                    ),
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
