import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/features/settings/view/widgets/animated_settings_background.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:collection/collection.dart'; 
import 'package:intl/intl.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  // Helper para obtener el color dinámico basado en el perfil
  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    return getAvatarColorById(profile.idAvatarSeleccionado);
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Recordatorio de Estudio':
        return Icons.schedule;
      case 'Amigos':
        return Icons.people_alt_outlined;
      case 'Retos y Novedades':
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications;
    }
  }

  // --- ¡NUEVO! ---
  // Diálogo de confirmación para el Master Switch
  Future<void> _showConfirmationDialog(
    BuildContext context, 
    WidgetRef ref, 
    bool newValue,
    ColorScheme colors,
  ) async {
    // Si están encendiendo, no preguntes, solo hazlo.
    if (newValue) {
      ref.read(notificationSettingsProvider.notifier).updateAllEnabled(true);
      return;
    }

    // Si están apagando, pregunta.
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.surfaceContainer,
          title: const Text('¿Desactivar todo?'),
          content: const Text('¿Estás seguro de que quieres desactivar todas las notificaciones de la aplicación?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar', style: TextStyle(color: colors.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );

    // Si confirmaron (pop(true)), entonces ejecuta la acción
    if (didConfirm == true) {
      ref.read(notificationSettingsProvider.notifier).updateAllEnabled(false);
    }
    // Si canceló o tocó fuera del diálogo, NO hacer nada
    // El provider mantiene su valor anterior y el switch se actualizará automáticamente
    // gracias a didUpdateWidget en SettingsSwitchTile
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final notificationSettingsState = ref.watch(notificationSettingsProvider);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _NotificationsLoadingShimmer(colors: colors),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          // Calculamos el color dinámico una sola vez
          final dynamicColor = _getDynamicColor(profile, colors);
          
          return Stack(
            children: [
              // --- FONDO ANIMADO COMPARTIDO (optimizado) ---
              AnimatedSettingsBackground(
                profile: profile,
                colors: colors,
                isKeyboardVisible: isKeyboardVisible,
              ),
              
              // --- CONTENIDO ---
              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR (Sin cambios) ---
                    // ... (Idéntico) ...
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
                              'Notificaciones',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // --- ¡LISTA DE OPCIONES CORREGIDA! ---
                    Expanded(
                      child: notificationSettingsState.when(
                        loading: () => _NotificationsLoadingShimmer(colors: colors),
                        error: (e, s) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error al cargar: $e', textAlign: TextAlign.center),
                          )
                        ),
                        data: (settings) {
                          
                          // --- LÓGICA DE AGRUPACIÓN (CORREGIDA Y CON FILTROS) ---
                          
                          // 1. Estado del "Master Switch"
                          // El Master Switch SÍ debe considerar TODAS las settings (visibles y ocultas)
                          final bool masterSwitchState = settings.isEmpty 
                            ? false 
                            : settings.any((s) => s.habilitado);

                          // --- ¡NUEVA LÓGICA DE FILTRADO! ---
                          // Define los tipos "ocultos" que NO queremos mostrar en la UI
                          const tiposOcultos = {
                            'Recordatorio de Racha',
                            'Recordatorio de Inactividad',
                          };

                          // Crea una NUEVA lista que solo contenga los settings VISIBLES
                          final visibleSettings = settings.where(
                            (s) => !tiposOcultos.contains(s.nombreTipo.trim())
                          ).toList();
                          // --- FIN DE LÓGICA DE FILTRADO ---


                          // 2. Buscamos el recordatorio (¡usando visibleSettings!)
                          final reminderSetting = visibleSettings.firstWhereOrNull(
                            (s) => s.nombreTipo.trim() == 'Recordatorio de Estudio'
                          );
                          
                          // 3. Buscamos los settings de "Amigos" (¡usando visibleSettings!)
                          final amigosSettings = visibleSettings.where(
                            (s) => s.nombreTipo.trim() == 'Nuevos Seguidores'
                          ).toList();

                          // 4. Buscamos los settings de "Retos y Novedades" (¡usando visibleSettings!)
                          final retosSettings = visibleSettings.where(
                            (s) => s.nombreTipo.trim() == 'Nuevos Retos' || s.nombreTipo.trim() == 'Novedades'
                          ).toList();
                          // --- FIN DE LA LÓGICA DE AGRUPACIÓN ---

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            children: [
                              // --- ¡NUEVO! SECCIÓN 1: GENERAL (TU IDEA) ---
                              FadeInDown(
                                child: SectionHeader(
                                  title: 'General', 
                                  icon: Icons.tune, 
                                  colors: colors
                                )
                              ),
                              FadeInDown(
                                delay: const Duration(milliseconds: 100),
                                child: SettingsSwitchTile(
                                  title: 'Permitir notificaciones',
                                  subtitle: masterSwitchState 
                                    ? 'Todo activado' 
                                    : 'Todo desactivado',
                                  icon: Icons.notifications,
                                  dynamicColor: dynamicColor,
                                  initialValue: masterSwitchState,
                                  onChanged: (newValue) {
                                    // ¡Llama al diálogo!
                                    _showConfirmationDialog(context, ref, newValue, colors);
                                  },
                                ),
                              ),

                              // --- SECCIÓN 2: RECORDATORIOS (¡AHORA SÍ APARECE!) ---
                              if (reminderSetting != null)...[
                                FadeInDown(
                                  delay: const Duration(milliseconds: 200),
                                  child: SectionHeader(
                                  title: 'Recordatorios', 
                                  icon: Icons.schedule, 
                                  colors: colors
                                  )
                                ),
                                FadeInDown(
                                  delay: const Duration(milliseconds: 300),
                                  child: SettingsNavigationTile(
                                    title: 'Recordatorio de Estudio',
                                    subtitle: reminderSetting.habilitado 
                                        ? (reminderSetting.horaNotificacion != null 
                                          ? 'Diario a las ${DateFormat.jm().format(DateTime(2024, 1, 1, _stringToTimeOfDay(reminderSetting.horaNotificacion)!.hour, _stringToTimeOfDay(reminderSetting.horaNotificacion)!.minute))}' 
                                          : 'Toca para fijar hora')
                                        : 'Desactivado',
                                    icon: _getIconForCategory('Recordatorio de Estudio'),
                                    dynamicColor: dynamicColor,
                                    onTap: () { 
                                      context.push(
                                        '/settings/notifications/reminder',
                                        extra: reminderSetting
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // --- SECCIÓN 3: ACTIVIDAD ---
                              FadeInDown(
                                delay: const Duration(milliseconds: 400),
                                child: SectionHeader(
                                  title: 'Actividad', 
                                  icon: Icons.group, 
                                  colors: colors
                                )
                              ),
                              if (amigosSettings.isNotEmpty)
                                FadeInDown(
                                  delay: const Duration(milliseconds: 500),
                                  child: SettingsNavigationTile(
                                    title: 'Amigos',
                                    subtitle: 'Alertas de actividad social',
                                    icon: _getIconForCategory('Amigos'),
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      context.push(
                                        '/settings/notifications/category',
                                        extra: {
                                          'title': 'Amigos',
                                          'settings': amigosSettings,
                                        },
                                      );
                                    },
                                  ),
                                ),
                              if (retosSettings.isNotEmpty)
                                FadeInDown(
                                  delay: const Duration(milliseconds: 600),
                                  child: SettingsNavigationTile(
                                    title: 'Retos y Novedades',
                                    subtitle: 'Alertas de nuevos desafíos y anuncios',
                                    icon: _getIconForCategory('Retos y Novedades'),
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      context.push(
                                        '/settings/notifications/category',
                                        extra: {
                                          'title': 'Retos y Novedades',
                                          'settings': retosSettings,
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
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

  // --- Helper method ---
  TimeOfDay? _stringToTimeOfDay(String? hora) {
    if (hora == null) return null;
    try {
      final parts = hora.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Error parseando hora: $e');
      return null;
    }
  }
}

// ... (El shimmer se queda igual) ...
class _NotificationsLoadingShimmer extends StatelessWidget {
// ... (Idéntico) ...
  final ColorScheme colors;
  const _NotificationsLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors( 
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerHighest,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            ...List.generate(3, (index) => Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(18)
              ),
            )),
          ],
        ),
      ),
    );
  }
}