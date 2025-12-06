import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/shared/widgets/animated_settings_background.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/shared/widgets/kitsu_action_modal.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView>
    with WidgetsBindingObserver {
  bool _isPageVisible = true;
  bool _isAppActive = true;
  bool? _optimisticDarkMode;

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

  void _showSignOutDialog(
    BuildContext context,
    WidgetRef ref,
    Color dynamicColor,
  ) {
    final colors = Theme.of(context).colorScheme;
    showKitsuActionModal(
      context: context,
      icon: Icons.logout,
      iconColor: colors.secondary,
      dynamicColor: dynamicColor,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que quieres finalizar tu sesión actual?',
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(audioControllerProvider).playClick();
            context.pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            ref.read(audioControllerProvider).playClick();

            context.pop();
            try {
              final authRepo = await ref.read(authRepositoryProvider.future);
              await authRepo.signOut();

              ref.invalidate(authStateProvider);
              ref.invalidate(profileRepositoryProvider);
              ref.invalidate(achievementNotifierProvider);
              ref.invalidate(avatarNotifierProvider);
              ref.invalidate(fcmServiceProvider);

              if (mounted) {
                showSuccessSnackbar(
                  context,
                  '¡Sesión cerrada!',
                  'Vuelve pronto a KitsuCode.',
                );
              }
            } catch (e) {
              if (mounted) {
                showErrorSnackbar(context, 'Error', e.toString());
              }
            }
          },
          child: const Text('Salir'),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    const String confirmationText = 'QUIERO ELIMINAR MI CUENTA';
    showKitsuActionModal(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: colors.error,
      dynamicColor: colors.error,
      title: 'Eliminar Cuenta',
      message:
          '¡Acción irreversible! Se borrarán todos tus datos permanentemente.',
      customContent: _buildDeleteModalContent(
        context,
        controller,
        confirmationText,
      ),
      actions: _buildDeleteModalActions(
        context,
        ref,
        controller,
        confirmationText,
      ),
    );
  }

  Widget _buildDeleteModalContent(
    BuildContext context,
    TextEditingController controller,
    String confirmationText,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escribe la frase completa para confirmar:',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autocorrect: false,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.error,
          ),
          decoration: InputDecoration(
            hintText: confirmationText,
            hintStyle: textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withAlpha(77),
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error.withAlpha(128)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error.withAlpha(128)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDeleteModalActions(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    String confirmationText,
  ) {
    final colors = Theme.of(context).colorScheme;
    return [
      TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          ref.read(audioControllerProvider).playClick();
          context.pop();
        },
        child: const Text('Cancelar'),
      ),
      AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final bool canDelete = controller.text.trim() == confirmationText;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canDelete
                  ? colors.error
                  : colors.onSurface.withAlpha(31),
              foregroundColor: canDelete
                  ? colors.onError
                  : colors.onSurface.withAlpha(97),
              disabledBackgroundColor: colors.onSurface.withAlpha(31),
              disabledForegroundColor: colors.onSurface.withAlpha(97),
            ),
            onPressed: canDelete
                ? () async {
                    HapticFeedback.heavyImpact();
                    ref.read(audioControllerProvider).playError();

                    context.pop();
                    showHelpSnackbar(
                      context,
                      'Procesando...',
                      'Eliminando tu cuenta...',
                    );
                    try {
                      final authRepo = await ref.read(
                        authRepositoryProvider.future,
                      );
                      await authRepo.deleteAccount();
                    } catch (e) {
                      if (!mounted) return;
                      showErrorSnackbar(context, 'Error', e.toString());
                    }
                  }
                : null,
            child: const Text('Eliminar Permanentemente'),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isSystemDark = platformBrightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: _SettingsLoadingShimmer(colors: colors),
      );
    }

    final currentAuthUserId = authState.value?.session?.user.id;

    if (currentAuthUserId == null) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: _SettingsLoadingShimmer(colors: colors),
      );
    }

    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final preferenciasState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _SettingsLoadingShimmer(colors: colors),

        error: (e, s) => _SettingsLoadingShimmer(colors: colors),

        data: (profile) {
          final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
          final dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : AllStatsView.getHeaderColor(profile, colors);

          return VisibilityDetector(
            key: const Key('settings-view-detector'),
            onVisibilityChanged: (visibilityInfo) {
              if (!mounted) return;
              setState(() {
                _isPageVisible = visibilityInfo.visibleFraction > 0.1;
              });
            },
            child: Stack(
              children: [
                if (_isAppActive && _isPageVisible)
                  RepaintBoundary(
                    child: AnimatedSettingsBackground(
                      profile: profile,
                      colors: colors,
                      isKeyboardVisible: isKeyboardVisible,
                    ),
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
                                'Configuración',
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
                              child: SectionHeader(
                                title: 'Preferencias',
                                icon: Icons.palette_outlined,
                                colors: colors,
                              ),
                            ),
                            preferenciasState.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, s) => Center(
                                child: Text('Error al cargar preferencias: $e'),
                              ),
                              data: (prefs) {
                                final String themeFromDB = prefs.temaVisual;
                                final bool realIsDark;
                                if (themeFromDB == 'system') {
                                  realIsDark = isSystemDark;
                                } else {
                                  realIsDark = (themeFromDB == 'dark');
                                }

                                final bool switchValue =
                                    _optimisticDarkMode ?? realIsDark;

                                return FadeInDown(
                                  delay: const Duration(milliseconds: 200),
                                  child: Column(
                                    children: [
                                      SettingsSwitchTile(
                                        title: switchValue
                                            ? 'Modo Oscuro'
                                            : 'Modo Claro',
                                        icon: switchValue
                                            ? Icons.dark_mode_outlined
                                            : Icons.light_mode_outlined,
                                        subtitle:
                                            'Alternar entre tema claro y oscuro',
                                        dynamicColor: dynamicColor,
                                        initialValue: switchValue,
                                        onChanged: (value) {
                                          HapticFeedback.lightImpact();
                                          ref
                                              .read(audioControllerProvider)
                                              .playClick();

                                          setState(() {
                                            _optimisticDarkMode = value;
                                          });

                                          Future.delayed(
                                            const Duration(milliseconds: 320),
                                            () {
                                              if (!mounted) return;

                                              final newTheme = value
                                                  ? 'dark'
                                                  : 'light';

                                              ref
                                                  .read(
                                                    settingsProvider.notifier,
                                                  )
                                                  .updateTemaVisual(newTheme)
                                                  .then((_) {
                                                    if (mounted) {
                                                      setState(() {
                                                        _optimisticDarkMode =
                                                            null;
                                                      });
                                                    }
                                                  });
                                            },
                                          );
                                        },
                                      ),
                                      SettingsSwitchTile(
                                        title: 'Efectos de Sonido',
                                        subtitle:
                                            'Activar o desactivar los sonidos',
                                        icon: Icons.volume_up_outlined,
                                        dynamicColor: dynamicColor,
                                        initialValue: prefs.sonidoEfectos,
                                        onChanged: (value) {
                                          HapticFeedback.lightImpact();
                                          ref
                                              .read(audioControllerProvider)
                                              .playClick();
                                          ref
                                              .read(settingsProvider.notifier)
                                              .updateSonidoEfectos(value);
                                        },
                                      ),
                                      SettingsSliderTile(
                                        title: 'Volumen Global',
                                        icon: Icons.music_note_outlined,
                                        dynamicColor: dynamicColor,
                                        initialValue: prefs.volumenAudio,
                                        onChanged: (value) {
                                          ref
                                              .read(settingsProvider.notifier)
                                              .updateVolumenAudio(value);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            FadeInDown(
                              delay: const Duration(milliseconds: 500),
                              child: Column(
                                children: [
                                  SectionHeader(
                                    title: 'Seguridad',
                                    icon: Icons.security_outlined,
                                    colors: colors,
                                  ),
                                  SettingsNavigationTile(
                                    title: 'Cambiar Contraseña',
                                    subtitle: 'Actualiza tu contraseña',
                                    icon: Icons.lock_outline,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(audioControllerProvider)
                                          .playClick();
                                      context.pushNamed('change-password');
                                    },
                                  ),
                                ],
                              ),
                            ),

                            FadeInDown(
                              delay: const Duration(milliseconds: 800),
                              child: Column(
                                children: [
                                  SectionHeader(
                                    title: 'Notificaciones',
                                    icon: Icons.notifications_outlined,
                                    colors: colors,
                                  ),
                                  SettingsNavigationTile(
                                    title: 'Configuración de Alertas',
                                    subtitle:
                                        'Recordatorios, amigos y novedades',
                                    icon: Icons.campaign_outlined,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(audioControllerProvider)
                                          .playClick();
                                      context.push('/settings/notifications');
                                    },
                                  ),
                                ],
                              ),
                            ),

                            FadeInDown(
                              delay: const Duration(milliseconds: 1000),
                              child: Column(
                                children: [
                                  SectionHeader(
                                    title: 'Soporte',
                                    icon: Icons.help_outline_rounded,
                                    colors: colors,
                                  ),
                                  SettingsNavigationTile(
                                    title: 'Ayuda y Sugerencias',
                                    subtitle:
                                        'Envía un reporte de error o sugerencia',
                                    icon: Icons.support_agent,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(audioControllerProvider)
                                          .playClick();
                                      context.push('/settings/support');
                                    },
                                  ),
                                ],
                              ),
                            ),

                            FadeInDown(
                              delay: const Duration(milliseconds: 1200),
                              child: Column(
                                children: [
                                  SectionHeader(
                                    title: 'Zona de Riesgo',
                                    icon: Icons.warning_amber_rounded,
                                    colors: colors,
                                  ),
                                  SettingsDestructiveTile(
                                    title: 'Eliminar Cuenta',
                                    subtitle:
                                        'Elimina tu cuenta permanentemente',
                                    icon: Icons.delete_forever_outlined,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(audioControllerProvider)
                                          .playClick();
                                      _showDeleteAccountDialog(context, ref);
                                    },
                                  ),
                                  SettingsDestructiveTile(
                                    title: 'Cerrar Sesión',
                                    subtitle: 'Finaliza tu sesión actual',
                                    icon: Icons.logout,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(audioControllerProvider)
                                          .playClick();
                                      _showSignOutDialog(
                                        context,
                                        ref,
                                        dynamicColor,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
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

class _SettingsLoadingShimmer extends StatelessWidget {
  final ColorScheme colors;
  const _SettingsLoadingShimmer({required this.colors});

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
            ...List.generate(
              5,
              (index) => Container(
                height: 70,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
