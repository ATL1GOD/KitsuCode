// lib/features/settings/view/settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:kitsucode/shared/widgets/kitsu_action_modal.dart'; // Importa el modal

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {

  void _showSignOutDialog(BuildContext context, WidgetRef ref, Color dynamicColor) {
    final colors = Theme.of(context).colorScheme;

    showKitsuActionModal(
      context: context,
      icon: Icons.logout,
      iconColor: colors.secondary,
      dynamicColor: dynamicColor, // <-- ¡AURA APLICADA!
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que quieres finalizar tu sesión actual?',
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: () {
            context.pop(); 
            try {
              ref.read(authRepositoryProvider).signOut();
              showSuccessSnackbar(
                context,
                '¡Sesión cerrada!',
                'Vuelve pronto a KitsuCode.',
              );
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
      dynamicColor: colors.error, // <-- ¡AURA DE PELIGRO APLICADA!
      title: 'Eliminar Cuenta',
      message:
          '¡Acción irreversible! Se borrarán todos tus datos permanentemente.',
      customContent:
          _buildDeleteModalContent(context, controller, confirmationText),
      actions:
          _buildDeleteModalActions(context, ref, controller, confirmationText),
    );
  }

  Widget _buildDeleteModalContent(BuildContext context,
      TextEditingController controller, String confirmationText) {
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
          style: textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: colors.error),
          decoration: InputDecoration(
            hintText: confirmationText,
            hintStyle: textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error.withOpacity(0.5)),
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
      String confirmationText) {
    final colors = Theme.of(context).colorScheme;

    return [
      TextButton(
        onPressed: () => context.pop(),
        child: const Text('Cancelar'),
      ),

      AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final bool canDelete = controller.text.trim() == confirmationText;
          
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canDelete ? colors.error : colors.onSurface.withOpacity(0.12),
              foregroundColor: canDelete
                  ? colors.onError
                  : colors.onSurface.withOpacity(0.38),
              disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
              disabledForegroundColor: colors.onSurface.withOpacity(0.38),
            ),
            onPressed: canDelete
                ? () async {
                    context.pop();
                    showHelpSnackbar(
                        context, 'Procesando...', 'Eliminando tu cuenta...');
                    try {
                      await ref.read(authRepositoryProvider).deleteAccount();
                    } catch (e) {
                      if (!mounted) return;
                      showErrorSnackbar(context, 'Error', e.toString());
                    }
                  }
                : null, // Deshabilitado
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
    
    // --- NUEVO: Detectar si el teclado está visible ---
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    // --- FIN NUEVO ---

    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: _SettingsLoadingShimmer(colors: colors),
      );
    }

    final currentAuthUserId = authState.value?.session?.user.id;
    if (currentAuthUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final preferenciasState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _SettingsLoadingShimmer(colors: colors),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              AnimatedSettingsBackground(
                profile: profile,
                colors: colors,
                isKeyboardVisible: isKeyboardVisible, // <-- ¡AQUÍ SE PASA EL ESTADO!
              ),
              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR (Sin Cambios) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
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
                                      color:
                                          colors.outlineVariant.withAlpha(130))),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: colors.onSurface),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Configuración',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // --- LISTA DE OPCIONES (¡AGRUPACIÓN OPTIMIZADA!) ---
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        children: [
                          // 1. Sección: Preferencias - HEADER
                          FadeInDown(
                            delay: const Duration(milliseconds: 100),
                            child: SectionHeader(
                                title: 'Preferencias',
                                icon: Icons.palette_outlined,
                                colors: colors),
                          ),
                          // 1. Sección: Preferencias - CONTENT (AGRUPADA)
                          preferenciasState.when(
                            loading: () => const Center(
                                child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              )),
                            error: (e, s) => Center(
                                child: Text('Error al cargar preferencias: $e')),
                            data: (prefs) {
                              final String themeFromDB = prefs.temaVisual;
                              final bool isDarkMode;
                              if (themeFromDB == 'system') {
                                isDarkMode = isSystemDark;
                              } else {
                                isDarkMode = (themeFromDB == 'dark');
                              }
                              // UN SOLO FadeInDown para todos los tiles de Preferencias.
                              return FadeInDown(
                                delay: const Duration(milliseconds: 200),
                                child: Column(
                                  children: [
                                    SettingsSwitchTile(
                                      title: isDarkMode
                                          ? 'Modo Oscuro'
                                          : 'Modo Claro',
                                      icon: isDarkMode
                                          ? Icons.dark_mode_outlined
                                          : Icons.light_mode_outlined,
                                      subtitle:
                                          'Alternar entre tema claro y oscuro',
                                      dynamicColor: dynamicColor,
                                      initialValue: isDarkMode,
                                      onChanged: (value) {
                                        final newTheme =
                                            value ? 'dark' : 'light';
                                        ref
                                            .read(settingsProvider.notifier)
                                            .updateTemaVisual(newTheme);
                                      },
                                    ),
                                    SettingsSwitchTile(
                                      title: 'Efectos de Sonido',
                                      subtitle: 'Activar o desactivar los sonidos',
                                      icon: Icons.volume_up_outlined,
                                      dynamicColor: dynamicColor,
                                      initialValue: prefs.sonidoEfectos,
                                      onChanged: (value) {
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

                          // 2. Sección: SEGURIDAD (AGRUPADA)
                          FadeInDown(
                            delay: const Duration(milliseconds: 500),
                            child: Column(
                              children: [
                                SectionHeader(
                                    title: 'Seguridad', // <-- TÍTULO CAMBIADO
                                    icon: Icons.security_outlined,
                                    colors: colors),
                                // ELIMINADO: SettingsNavigationTile('Mi Información')
                                SettingsNavigationTile(
                                  title: 'Cambiar Contraseña',
                                  subtitle: 'Actualiza tu contraseña',
                                  icon: Icons.lock_outline,
                                  dynamicColor: dynamicColor,
                                  onTap: () {
                                    context.pushNamed('change-password');
                                  },
                                ),
                              ],
                            ),
                          ),

                          // 3. Sección: Notificaciones (AGRUPADA)
                          FadeInDown(
                            delay: const Duration(milliseconds: 800),
                            child: Column(
                              children: [
                                SectionHeader(
                                    title: 'Notificaciones',
                                    icon: Icons.notifications_outlined,
                                    colors: colors),
                                SettingsNavigationTile(
                                  title: 'Configuración de Alertas',
                                  subtitle:
                                      'Recordatorios, amigos y novedades',
                                  icon: Icons.campaign_outlined,
                                  dynamicColor: dynamicColor,
                                  onTap: () {
                                    context.push('/settings/notifications');
                                  },
                                ),
                              ],
                            ),
                          ),

                          // 4. Sección: Soporte (AGRUPADA)
                          FadeInDown(
                            delay: const Duration(milliseconds: 1000),
                            child: Column(
                              children: [
                                SectionHeader(
                                    title: 'Soporte',
                                    icon: Icons.help_outline_rounded,
                                    colors: colors),
                                SettingsNavigationTile(
                                  title: 'Ayuda y Sugerencias',
                                  subtitle: 'Envía un reporte de error o sugerencia',
                                  icon: Icons.support_agent,
                                  dynamicColor: dynamicColor,
                                  onTap: () {
                                    context.push('/settings/support');
                                  },
                                ),
                              ],
                            ),
                          ),

                          // 5. Sección: Zona de Riesgo (AGRUPADA)
                          FadeInDown(
                              delay: const Duration(milliseconds: 1200),
                              child: Column(
                                children: [
                                  SectionHeader(
                                      title: 'Zona de Riesgo',
                                      icon: Icons.warning_amber_rounded,
                                      colors: colors),
                                  SettingsDestructiveTile(
                                    title: 'Eliminar Cuenta',
                                    subtitle:
                                        'Elimina tu cuenta permanentemente',
                                    icon: Icons.delete_forever_outlined,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      _showDeleteAccountDialog(context, ref);
                                    },
                                  ),
                                  SettingsDestructiveTile(
                                    title: 'Cerrar Sesión',
                                    subtitle: 'Finaliza tu sesión actual',
                                    icon: Icons.logout,
                                    dynamicColor: dynamicColor,
                                    onTap: () {
                                      _showSignOutDialog(
                                          context, ref, dynamicColor);
                                    },
                                  ),
                                ],
                              )),

                          const SizedBox(height: 40),
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

// --- SHIMMER DE CARGA (Sin cambios) ---
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
            const SizedBox(height: 60), // Espacio para el appbar
            ...List.generate(
                5,
                (index) => Container(
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18)),
                    )),
          ],
        ),
      ),
    );
  }
}