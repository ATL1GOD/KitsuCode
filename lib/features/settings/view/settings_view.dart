import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // ¡Necesario para detectar el tema del sistema!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
// Importamos el provider de settings
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/features/settings/view/widgets/animated_settings_background.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- ¡LÓGICA DE TEMA! ---
    // 1. Detecta el tema actual del dispositivo (teléfono)
    final platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isSystemDark = platformBrightness == Brightness.dark;

    // Verificar autenticación PRIMERO
    final authState = ref.watch(authStateProvider);
    
    // Mientras se carga la autenticación, mostrar loading
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

    // Solo ahora cargamos las preferencias (cuando ya sabemos que hay usuario)
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final preferenciasState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _SettingsLoadingShimmer(colors: colors),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          // Calculamos el color dinámico una vez para usar en los tiles
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);
          
          return Stack(
            children: [
              // --- FONDO ANIMADO OPTIMIZADO ---
              AnimatedSettingsBackground(
                profile: profile,
                colors: colors,
              ),
              
              // --- CONTENIDO PRINCIPAL ---
              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR (Sin Cambios) ---
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
                              'Configuración',
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
                          // --- 1. Sección: Preferencias ---
                          FadeInDown(
                            delay: const Duration(milliseconds: 100),
                            child: SectionHeader(title: 'Preferencias', icon: Icons.palette_outlined, colors: colors)
                          ),
                          
                          preferenciasState.when(
                            loading: () => const Center(child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            )),
                            error: (e, s) => Center(child: Text('Error al cargar preferencias: $e')),
                            data: (prefs) {
                              
                              // --- ¡LÓGICA DE TEMA! ---
                              // 2. Resuelve el estado final del tema
                              final String themeFromDB = prefs.temaVisual;
                              final bool isDarkMode;

                              if (themeFromDB == 'system') {
                                isDarkMode = isSystemDark;
                              } else {
                                isDarkMode = (themeFromDB == 'dark');
                              }
                              
                              return Column(
                                children: [
                                  // --- ¡ESTE ES EL CAMBIO! ---
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 200),
                                    child: SettingsSwitchTile(
                                      // 3. Pasa el título y el ícono dinámicos
                                      title: isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                                      icon: isDarkMode 
                                          ? Icons.dark_mode_outlined 
                                          : Icons.light_mode_outlined,
                                      subtitle: 'Alternar entre tema claro y oscuro',
                                      dynamicColor: dynamicColor,
                                      // 4. El switch refleja el estado resuelto
                                      initialValue: isDarkMode, 
                                      onChanged: (value) {
                                        // 5. Guardamos 'dark' o 'light', NUNCA 'system'
                                        final newTheme = value ? 'dark' : 'light';
                                        ref.read(settingsProvider.notifier).updateTemaVisual(newTheme);
                                      },
                                    ),
                                  ),
                                  // --- FIN DEL CAMBIO ---

                                  FadeInDown(
                                    delay: const Duration(milliseconds: 300),
                                    child: SettingsSwitchTile(
                                      title: 'Efectos de Sonido',
                                      subtitle: 'Activar o desactivar los sonidos',
                                      icon: Icons.volume_up_outlined,
                                      dynamicColor: dynamicColor,
                                      initialValue: prefs.sonidoEfectos, 
                                      onChanged: (value) {
                                        ref.read(settingsProvider.notifier).updateSonidoEfectos(value);
                                      },
                                    ),
                                  ),
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 400),
                                    child: SettingsSliderTile(
                                      title: 'Volumen Global',
                                      icon: Icons.music_note_outlined,
                                      dynamicColor: dynamicColor,
                                      initialValue: prefs.volumenAudio,
                                      onChanged: (value) {
                                        // Usamos el notifier en 'onChanged' del slider
                                        ref.read(settingsProvider.notifier).updateVolumenAudio(value);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // --- 2. Sección: Perfil y Seguridad (Sin Cambios) ---
                          FadeInDown(
                            delay: const Duration(milliseconds: 500),
                            child: SectionHeader(title: 'Perfil y Seguridad', icon: Icons.security_outlined, colors: colors)
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 600),
                            child: SettingsNavigationTile(
                              title: 'Mi Información',
                              subtitle: 'Ver tu perfil, correo e ID',
                              icon: Icons.person_outline,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                context.push('/profile/$currentAuthUserId');
                              },
                            ),
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 700),
                            child: SettingsNavigationTile(
                              title: 'Cambiar Contraseña',
                              subtitle: 'Actualiza tu contraseña',
                              icon: Icons.lock_outline,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Navegando a cambiar contraseña... (No implementado)'))
                                );
                              },
                            ),
                          ),
                          
                          // --- 3. Sección: Notificaciones (Sin Cambios) ---
                          FadeInDown(
                            delay: const Duration(milliseconds: 800),
                            child: SectionHeader(title: 'Notificaciones', icon: Icons.notifications_outlined, colors: colors)
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 900),
                            child: SettingsNavigationTile(
                              title: 'Configuración de Alertas',
                              subtitle: 'Recordatorios, amigos y novedades',
                              icon: Icons.campaign_outlined,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                context.push('/settings/notifications');
                              },
                            ),
                          ),

                          // --- 4. Sección: Soporte (Sin Cambios) ---
                           FadeInDown(
                            delay: const Duration(milliseconds: 1000),
                            child: SectionHeader(title: 'Soporte', icon: Icons.help_outline_rounded, colors: colors)
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 1100),
                            child: SettingsNavigationTile(
                              title: 'Ayuda y Sugerencias',
                              subtitle: 'Envía un reporte de error o sugerencia',
                              icon: Icons.support_agent,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                context.push('/settings/support');
                              },
                            ),
                          ),

                          // --- 5. Sección: Zona de Riesgo (Sin Cambios) ---
                          FadeInDown(
                            delay: const Duration(milliseconds: 1200),
                            child: SectionHeader(title: 'Zona de Riesgo', icon: Icons.warning_amber_rounded, colors: colors)
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 1300),
                            child: SettingsDestructiveTile(
                              title: 'Eliminar Cuenta',
                              subtitle: 'Elimina tu cuenta permanentemente',
                              icon: Icons.delete_forever_outlined,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mostrar diálogo de eliminar cuenta...'))
                                );
                              },
                            ),
                          ),
                          FadeInDown(
                            delay: const Duration(milliseconds: 1400),
                            child: SettingsDestructiveTile(
                              title: 'Cerrar Sesión',
                              subtitle: 'Finaliza tu sesión actual',
                              icon: Icons.logout,
                              dynamicColor: dynamicColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cerrando sesión...'))
                                );
                                //ref.read(authStateProvider.notifier).signOut();
                              },
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
            ...List.generate(5, (index) => Container(
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