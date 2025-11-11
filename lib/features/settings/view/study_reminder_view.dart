import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
// ¡Importamos el nuevo provider local!
import 'package:kitsucode/features/notifications/provider/local_notification_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

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
    _selectedTime = widget.setting.timeOfDay;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      // Guardar en BD
      final timeString = NotificationSetting.timeOfDayToString(picked);
      ref.read(notificationSettingsProvider.notifier)
         .updateTime(widget.setting.preferenciaId, timeString);
      
      // --- ¡REEMPLAZAMOS EL TODO! ---
      // Volver a programar la alarma con la nueva hora
      ref.read(localNotificationProvider).scheduleStudyReminder(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El build y el profileState se quedan igual) ...
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        // ... (loading, error, stack, fondo, lottie, appbar... todo igual) ...
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);
          return Stack(
            children: [
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
              SafeArea(
                child: Column(
                  children: [
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
                              widget.setting.nombreTipo,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        children: [
                          // 1. El Switch para activar/desactivar
                          FadeInDown(
                            child: SettingsSwitchTile(
                              title: 'Activar Recordatorio',
                              subtitle: 'Recibir una notificación diaria para practicar',
                              icon: Icons.notifications_active_outlined,
                              dynamicColor: dynamicColor,
                              initialValue: _isEnabled,
                              onChanged: (newValue) {
                                setState(() {
                                  _isEnabled = newValue;
                                });
                                // Guardar en BD
                                ref.read(notificationSettingsProvider.notifier)
                                    .updateEnabled(widget.setting.preferenciaId, newValue);
                                
                                // --- ¡REEMPLAZAMOS EL TODO! ---
                                if (newValue) {
                                  // Si se activa, programar la alarma
                                  ref.read(localNotificationProvider).scheduleStudyReminder(_selectedTime);
                                } else {
                                  // Si se desactiva, cancelar la alarma
                                  ref.read(localNotificationProvider).cancelStudyReminder();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 2. El selector de hora
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isEnabled ? 1.0 : 0.5,
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              child: SettingsNavigationTile(
                                title: 'Hora de la notificación',
                                subtitle: _selectedTime.format(context), 
                                icon: Icons.access_time,
                                dynamicColor: dynamicColor,
                                onTap: _isEnabled ? () => _selectTime(context) : null,
                              ),
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