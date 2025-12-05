import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Haptics
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/core/providers/audio_provider.dart'; // Para Audio
// ✅ Importar helpers de avatar para el color correcto
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

/// Widget genérico para mostrar errores de aplicación/servidor (Supabase, Logic, Crash).
class GenericErrorView extends ConsumerWidget {
  final VoidCallback? onRetry;
  final String title;
  final String message;
  final bool showGoBack;

  const GenericErrorView({
    super.key,
    this.onRetry,
    this.title = '¡Algo salió mal!',
    this.message = 'Tuvimos un problema técnico con el servidor. El equipo de KitsuCode ya está investigando.',
    this.showGoBack = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- 1. LÓGICA DE COLOR DINÁMICO ---
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;
    
    // Intentamos obtener el perfil, pero manejamos si falla para no crear un bucle de errores
    AsyncValue? profileState;
    try {
      if (currentAuthUserId != null) {
        profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
      }
    } catch (_) {
      // Si falla cargar el perfil, no hacemos nada, usaremos color por defecto
    }

    final profile = profileState?.asData?.value;

    // ✅ Obtener lista de avatares para el color real
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

    final Color dynamicColor;
    if (profile != null) {
      dynamicColor = avatarsList.isNotEmpty
          ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
          : AllStatsView.getHeaderColor(profile, colors);
    } else {
      dynamicColor = colors.primary;
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          // --- 2. FONDO CON GRADIENTE ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dynamicColor.withAlpha(100), // ~40% opacidad
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          // --- 3. CONTENIDO CENTRADO ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ Imagen unificada (Alerta)
                    Image.asset(
                      'assets/images/home/alerta.webp', 
                      width: 200,
                      cacheWidth: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Mensaje
                    Text(
                      message,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Botones de Acción
                    Column(
                      children: [
                        // Botón REINTENTAR (Importante para fallos de API)
                        if (onRetry != null)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Intentar de nuevo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dynamicColor,
                                foregroundColor: colors.onPrimary,
                                elevation: 4,
                                shadowColor: dynamicColor.withOpacity(0.4),
                                textStyle: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                // 🔥 Feedback Sonoro y Háptico
                                HapticFeedback.mediumImpact();
                                ref.read(audioControllerProvider).playClick();
                                onRetry!();
                              },
                            ),
                          ),

                        if (onRetry != null && showGoBack) 
                          const SizedBox(height: 16),

                        // Botón VOLVER (Para salir de pantallas rotas)
                        if (showGoBack && context.canPop())
                          TextButton.icon(
                            icon: Icon(Icons.arrow_back_rounded, color: colors.secondary),
                            label: Text(
                              'Volver atrás',
                              style: TextStyle(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // 🔥 Feedback Sonoro y Háptico
                              HapticFeedback.lightImpact();
                              ref.read(audioControllerProvider).playClick();
                              context.pop();
                            },
                          ),
                      ],
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