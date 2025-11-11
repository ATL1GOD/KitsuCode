import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // ¡Importante para formatear la hora!
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
// --- ¡IMPORTAMOS EL NUEVO PROVIDER! ---
import 'package:kitsucode/features/notifications/provider/local_notification_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:lottie/lottie.dart';

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
      
      // --- 3. ¡CONECTADO! ---
      // Llama al servicio para (re)programar la alarma con la nueva hora
      ref.read(localNotificationProvider).scheduleStudyReminder(newTime);
      debugPrint('Alarma reprogramada para las $newTimeString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    
    final dynamicColor = profileState.value != null 
      ? AllStatsView.getHeaderColor(profileState.value!, colors)
      : colors.primary;

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
      body: Stack(
        children: [
          // --- FONDO y LOTTIE (Sin cambios) ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dynamicColor.withAlpha(100),
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7]
              ),
            ),
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              colors.secondaryFixedDim.withAlpha((255 * 0.8).round()),
              BlendMode.srcIn, 
            ),
            child: Lottie.asset(
              'assets/animations/spring.json', 
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
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
                      SettingsSwitchTile(
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
                          
                          // 3. ¡CONECTADO!
                          if (newValue) {
                            // Si se ACTIVA, programa la alarma
                            ref.read(localNotificationProvider)
                               .scheduleStudyReminder(_selectedTime);
                            debugPrint('Alarma activada para las ${_timeOfDayToString(_selectedTime)}');
                            
                            // También guardamos la hora por si se había desactivado
                            ref.read(notificationSettingsProvider.notifier).updateTime(
                              widget.setting.preferenciaId, 
                              _timeOfDayToString(_selectedTime)
                            );
                          } else {
                            // Si se DESACTIVA, cancela la alarma
                            ref.read(localNotificationProvider).cancelStudyReminder();
                            debugPrint('Alarma cancelada');

                            // Y guardamos NULL en la hora en la BD
                            ref.read(notificationSettingsProvider.notifier)
                              .updateTime(widget.setting.preferenciaId, null);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // 2. El selector de hora (deshabilitado si el switch está off)
                      SettingsNavigationTile(
                        title: 'Hora del recordatorio',
                        subtitle: timeSubtitle,
                        icon: Icons.schedule,
                        dynamicColor: dynamicColor,
                        // ¡CLAVE! Deshabilitado si _isEnabled es false
                        onTap: _isEnabled ? () => _pickTime(context) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}