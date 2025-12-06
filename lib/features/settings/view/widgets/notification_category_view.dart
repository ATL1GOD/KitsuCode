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

import 'package:visibility_detector/visibility_detector.dart';

import 'package:kitsucode/features/profile/view/all_stats_view.dart';

class NotificationCategoryView extends ConsumerStatefulWidget {
  final String title;
  final List<NotificationSetting> settings;

  const NotificationCategoryView({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  ConsumerState<NotificationCategoryView> createState() =>
      _NotificationCategoryViewState();
}

class _NotificationCategoryViewState
    extends ConsumerState<NotificationCategoryView>
    with WidgetsBindingObserver {
  bool _isPageVisible = true;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
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

  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    final avatarsList = ref.read(currentUserAvatarsProvider).value ?? [];
    return avatarsList.isNotEmpty
        ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
        : AllStatsView.getHeaderColor(profile, colors);
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

    final asyncLiveSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = _getDynamicColor(profile, colors);

          if (asyncLiveSettings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (asyncLiveSettings.hasError) {
            return Center(
              child: Text(
                'Error al cargar configuración de notificaciones: ${asyncLiveSettings.error}',
              ),
            );
          }

          final liveSettingsList = asyncLiveSettings.value ?? [];

          return VisibilityDetector(
            key: Key('notification-category-detector-${widget.title}'),
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
                          dynamicColor.withAlpha(100),
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
                              onTap: () => context.pop(),
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
                                widget.title,
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
                            ...List.generate(widget.settings.length, (index) {
                              final setting = widget.settings[index];
                              final liveSetting = liveSettingsList.firstWhere(
                                (s) => s.preferenciaId == setting.preferenciaId,
                                orElse: () => setting,
                              );

                              return FadeInDown(
                                delay: Duration(
                                  milliseconds: 100 + (index * 100),
                                ),
                                child: SettingsSwitchTile(
                                  title: liveSetting.nombreTipo,
                                  subtitle:
                                      liveSetting.descripcion ??
                                      'Activar o desactivar esta alerta',
                                  icon: Icons.notifications_active_outlined,
                                  dynamicColor: dynamicColor,
                                  initialValue: liveSetting.habilitado,
                                  onChanged: (newValue) {
                                    ref
                                        .read(
                                          notificationSettingsProvider.notifier,
                                        )
                                        .updateEnabled(
                                          liveSetting.preferenciaId,
                                          newValue,
                                        );
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
            ),
          );
        },
      ),
    );
  }
}
