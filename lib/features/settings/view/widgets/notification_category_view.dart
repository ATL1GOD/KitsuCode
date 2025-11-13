// lib/features/settings/view/widgets/notification_category_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/shared/widgets/animated_settings_background.dart'; 
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart'; 
import 'package:animate_do/animate_do.dart';

// Esta vista es genérica. Recibe un título y una lista de settings.
class NotificationCategoryView extends ConsumerWidget {
  final String title;
  final List<NotificationSetting> settings;

  const NotificationCategoryView({
    super.key, 
    required this.title,
    required this.settings
  });

  // Helper para obtener el color dinámico
  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    return getAvatarColorById(profile.idAvatarSeleccionado);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtenemos el perfil solo para el color dinámico del fondo
    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // --- 1. OBTENER EL ESTADO DE NOTIFICACIONES EN VIVO (ASYNC) ---
    // Esto fuerza a que la vista se reconstruya cuando el provider cambia.
    final asyncLiveSettings = ref.watch(notificationSettingsProvider); 

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = _getDynamicColor(profile, colors);
          
          // Manejar el estado de carga/error del provider de notificaciones
          if (asyncLiveSettings.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }
          if (asyncLiveSettings.hasError) {
             return Center(child: Text('Error al cargar configuración de notificaciones: ${asyncLiveSettings.error}'));
          }
          
          final liveSettingsList = asyncLiveSettings.value ?? [];

          return Stack(
            children: [
              // --- FONDO ANIMADO OPTIMIZADO ---
              // (Mantienes la animación según tu solicitud, aunque es costosa)
              AnimatedSettingsBackground(
                profile: profile,
                colors: colors,
                isKeyboardVisible: isKeyboardVisible,
              ),
            
              // --- CONTENIDO ---
              SafeArea(
            child: Column(
              children: [
                // --- BARRA SUPERIOR (Idéntica) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: colors.surface.withAlpha(50),
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.outlineVariant.withAlpha(130))
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title, // <-- Usamos el título que nos pasaron
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- LISTA DE SWITCHES ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    children: [
                      // Usamos la lista pasada en el constructor para iterar (la lista fija)
                      // Pero usamos la lista VIVA (liveSettingsList) para obtener el estado.
                      ...List.generate(settings.length, (index) {
                        final setting = settings[index];
                        
                        // --- 2. ENCONTRAR EL VALOR HABILITADO EN VIVO ---
                        final liveSetting = liveSettingsList.firstWhere(
                            (s) => s.preferenciaId == setting.preferenciaId,
                            // Fallback al valor inicial si no se encuentra (seguridad)
                            orElse: () => setting, 
                        );

                        return FadeInDown(
                          delay: Duration(milliseconds: 100 + (index * 100)),
                          child: SettingsSwitchTile(
                            title: liveSetting.nombreTipo,
                            subtitle: liveSetting.descripcion ?? 'Activar o desactivar esta alerta',
                            // TODO: Mapear un ícono basado en setting.nombreTipo
                            icon: Icons.notifications_active_outlined, 
                            dynamicColor: dynamicColor,
                            initialValue: liveSetting.habilitado, // <-- USA EL VALOR EN VIVO
                            onChanged: (newValue) {
                              // Esto dispara la actualización del provider, lo que fuerza
                              // un rebuild de esta vista y actualiza el switch.
                              ref.read(notificationSettingsProvider.notifier)
                                  .updateEnabled(liveSetting.preferenciaId, newValue);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}