import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // ¡Importante para formatear la hora!
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
// --- ¡IMPORTAMOS EL NUEVO PROVIDER! ---
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/shared/widgets/animated_settings_background.dart';
import 'package:animate_do/animate_do.dart';

// --- Helpers para convertir (los movimos de tu versión anterior) ---
TimeOfDay? _stringToTimeOfDay(String? hora) {
  if (hora == null) return null;
  try {
    final parts = hora.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  } catch (e) {
    debugPrint('Error parseando hora: $e');
    // Si la hora está corrupta, devuelve la hora por defecto (7pm)
    return const TimeOfDay(hour: 19, minute: 0);
  }
}

String _timeOfDayToString(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
// --- Fin de Helpers ---

class StudyReminderView extends ConsumerStatefulWidget {
  final NotificationSetting setting;
  const StudyReminderView({super.key, required this.setting});

  @override
  ConsumerState<StudyReminderView> createState() => _StudyReminderViewState();
}

class _StudyReminderViewState extends ConsumerState<StudyReminderView> {
  late bool _isEnabled;
  late TimeOfDay _selectedTime;

  // Helper para obtener el color dinámico basado en el perfil
  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    return getAvatarColorById(profile.idAvatarSeleccionado);
  }

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.setting.habilitado;
    // Usamos el helper. Si es null (nunca debería por nuestra lógica de BD),
    // ponemos las 7pm por si acaso.
    _selectedTime = _stringToTimeOfDay(widget.setting.horaNotificacion) ?? 
                    const TimeOfDay(hour: 19, minute: 0);
  }

  Future<void> _pickTime(BuildContext context) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (newTime != null) {
      // 1. Actualiza el estado local de la UI
      setState(() {
        _selectedTime = newTime;
      });
      
      // 2. Guarda en Supabase y actualiza el provider
      final newTimeString = _timeOfDayToString(newTime);
      ref.read(notificationSettingsProvider.notifier).updateTime(
        widget.setting.preferenciaId, 
        newTimeString
      );
      
      // La programación de la notificación se maneja vía FCM + Edge Functions (cron job)
      debugPrint('Hora de recordatorio actualizada para las $newTimeString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Formatear la hora para mostrarla en el tile
    String timeSubtitle;
    if (!_isEnabled) {
      timeSubtitle = 'Desactivado';
    } else {
      // Usamos 'intl' para formatear la hora a AM/PM (o 24h según el locale)
      final dt = DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute);
      timeSubtitle = DateFormat.jm().format(dt); // ej. "7:00 PM"
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          // Calcular el color dinámico basado en el avatar
          final dynamicColor = _getDynamicColor(profile, colors);
          
          return Stack(
            children: [
              // --- FONDO ANIMADO OPTIMIZADO ---
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
                          'Recordatorio de Estudio',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- LISTA DE OPCIONES ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    children: [
                      // 1. El Switch principal para Habilitar
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: SettingsSwitchTile(
                          title: 'Activar recordatorio',
                          subtitle: 'Recibe una notificación diaria para practicar.',
                          icon: Icons.notifications_active,
                          dynamicColor: dynamicColor,
                          initialValue: _isEnabled,
                          onChanged: (newValue) {
                            // 1. Actualiza el estado local
                            setState(() {
                              _isEnabled = newValue;
                            });
                          
                            // 2. Guarda en Supabase y actualiza el provider
                          ref.read(notificationSettingsProvider.notifier)
                              .updateEnabled(widget.setting.preferenciaId, newValue);
                          
                          if (newValue) {
                            // Si se ACTIVA, guardar hora en BD (FCM + Edge Functions se encargan de enviar)
                            debugPrint('Recordatorio activado para las ${_timeOfDayToString(_selectedTime)}');
                            
                            // También guardamos la hora por si se había desactivado
                            ref.read(notificationSettingsProvider.notifier).updateTime(
                              widget.setting.preferenciaId, 
                              _timeOfDayToString(_selectedTime)
                            );
                          } else {
                            // Si se DESACTIVA, solo actualizar BD (FCM dejará de enviar)
                            debugPrint('Recordatorio desactivado');

                            // Y guardamos NULL en la hora en la BD
                            ref.read(notificationSettingsProvider.notifier)
                              .updateTime(widget.setting.preferenciaId, null);
                          }
                        },
                      ),
                      ),

                      const SizedBox(height: 12),

                      // 2. El selector de hora (deshabilitado si el switch está off)
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: SettingsNavigationTile(
                          title: 'Hora del recordatorio',
                          subtitle: timeSubtitle,
                          icon: Icons.schedule,
                          dynamicColor: dynamicColor,
                          // ¡CLAVE! Deshabilitado si _isEnabled es false
                          onTap: _isEnabled ? () => _pickTime(context) : null,
                        ),
                      ),
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