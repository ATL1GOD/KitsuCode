import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/shared/widgets/animated_settings_background.dart';
import 'package:animate_do/animate_do.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

TimeOfDay? _stringToTimeOfDay(String? hora) {
  if (hora == null) return null;
  try {
    final parts = hora.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  } catch (e) {
    debugPrint('Error parseando hora: $e');
    return const TimeOfDay(hour: 19, minute: 0);
  }
}

String _timeOfDayToString(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class StudyReminderView extends ConsumerStatefulWidget {
  final NotificationSetting setting;
  const StudyReminderView({super.key, required this.setting});

  @override
  ConsumerState<StudyReminderView> createState() => _StudyReminderViewState();
}

class _StudyReminderViewState extends ConsumerState<StudyReminderView>
    with WidgetsBindingObserver {
  late bool _isEnabled;
  late TimeOfDay _selectedTime;

  bool _isPageVisible = true;
  bool _isAppActive = true;

  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    return getAvatarColorById(profile.idAvatarSeleccionado);
  }

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.setting.habilitado;
    _selectedTime =
        _stringToTimeOfDay(widget.setting.horaNotificacion) ??
        const TimeOfDay(hour: 19, minute: 0);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    HapticFeedback.lightImpact();
    ref.read(audioControllerProvider).playClick();

    final newTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (newTime != null) {
      HapticFeedback.mediumImpact();
      ref.read(audioControllerProvider).playSuccess();

      setState(() {
        _selectedTime = newTime;
      });
      final newTimeString = _timeOfDayToString(newTime);
      ref
          .read(notificationSettingsProvider.notifier)
          .updateTime(widget.setting.preferenciaId, newTimeString);
      debugPrint('Hora de recordatorio actualizada para las $newTimeString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentAuthUserId = ref
        .watch(authStateProvider)
        .value!
        .session!
        .user
        .id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    String timeSubtitle;
    if (!_isEnabled) {
      timeSubtitle = 'Desactivado';
    } else {
      final dt = DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute);
      timeSubtitle = DateFormat.jm().format(dt);
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
          final dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : _getDynamicColor(profile, colors);

          return VisibilityDetector(
            key: const Key('study-reminder-detector'),
            onVisibilityChanged: (visibilityInfo) {
              if (!mounted) return;
              setState(() {
                _isPageVisible = visibilityInfo.visibleFraction > 0.1;
              });
            },
            child: Stack(
              children: [
                if (_isAppActive && _isPageVisible)
                  AnimatedSettingsBackground(
                    profile: profile,
                    colors: colors,
                    isKeyboardVisible: isKeyboardVisible,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          dynamicColor.withAlpha((255 * 0.4).round()),
                          colors.surfaceContainerLowest,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),

                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(audioControllerProvider).playClick();
                                context.pop();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: colors.surface.withAlpha(50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.outlineVariant.withAlpha(130),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Recordatorio de Estudio',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          children: [
                            FadeInDown(
                              delay: const Duration(milliseconds: 100),
                              child: SettingsSwitchTile(
                                title: 'Activar recordatorio',
                                subtitle:
                                    'Recibe una notificación diaria para practicar.',
                                icon: Icons.notifications_active,
                                dynamicColor: dynamicColor,
                                initialValue: _isEnabled,
                                onChanged: (newValue) {
                                  HapticFeedback.lightImpact();
                                  ref.read(audioControllerProvider).playClick();

                                  setState(() {
                                    _isEnabled = newValue;
                                  });
                                  ref
                                      .read(
                                        notificationSettingsProvider.notifier,
                                      )
                                      .updateEnabled(
                                        widget.setting.preferenciaId,
                                        newValue,
                                      );
                                  if (newValue) {
                                    debugPrint(
                                      'Recordatorio activado para las ${_timeOfDayToString(_selectedTime)}',
                                    );
                                    ref
                                        .read(
                                          notificationSettingsProvider.notifier,
                                        )
                                        .updateTime(
                                          widget.setting.preferenciaId,
                                          _timeOfDayToString(_selectedTime),
                                        );
                                  } else {
                                    debugPrint('Recordatorio desactivado');
                                    ref
                                        .read(
                                          notificationSettingsProvider.notifier,
                                        )
                                        .updateTime(
                                          widget.setting.preferenciaId,
                                          null,
                                        );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeInDown(
                              delay: const Duration(milliseconds: 200),
                              child: SettingsNavigationTile(
                                title: 'Hora del recordatorio',
                                subtitle: timeSubtitle,
                                icon: Icons.schedule,
                                dynamicColor: dynamicColor,
                                onTap: _isEnabled
                                    ? () => _pickTime(context)
                                    : null,
                              ),
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
        },
      ),
    );
  }
}
