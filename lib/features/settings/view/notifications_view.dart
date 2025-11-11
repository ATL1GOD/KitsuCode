import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
// ¡Usando tus rutas!
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart'; 
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
// --- ¡IMPORTAMOS EL PAQUETE! ---
import 'package:collection/collection.dart'; 

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));
    final notificationSettingsState = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => _NotificationsLoadingShimmer(colors: colors),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
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
                              'Notificaciones',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // --- LISTA DE OPCIONES REALES ---
                    Expanded(
                      child: notificationSettingsState.when(
                        loading: () => _NotificationsLoadingShimmer(colors: colors),
                        error: (e, s) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            // Mostramos el error real en la UI
                            child: Text('Error al cargar: $e', textAlign: TextAlign.center),
                          )
                        ),
                        data: (settings) {
                          
                          // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                          // 1. Manejar el caso de lista vacía
                          if (settings.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'Aún no hay configuraciones de notificación. Esto puede tardar un momento si es tu primer inicio.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                            );
                          }

                          // 2. Separamos el recordatorio de forma segura
                          // Usamos 'firstWhereOrNull' del paquete 'collection'
                          final reminderSetting = settings.firstWhereOrNull(
                            (s) => s.esRecordatorioHora
                          );
                          
                          // 3. Obtenemos el resto de los switches
                          final generalSettings = settings.where(
                            (s) => !s.esRecordatorioHora
                          ).toList();
                          // --- FIN DE LA CORRECCIÓN ---

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            children: [
                              // --- SECCIÓN 1: RECORDATORIOS ---
                              // Solo muestra esta sección si se encontró un recordatorio
                              if (reminderSetting != null) ...[
                                FadeInDown(
                                  child: SectionHeader(
                                    title: 'Recordatorios', 
                                    icon: Icons.schedule, 
                                    colors: colors
                                  )
                                ),
                                FadeInDown(
                                  delay: const Duration(milliseconds: 100),
                                  child: SettingsNavigationTile(
                                    title: reminderSetting.nombreTipo,
                                    subtitle: reminderSetting.habilitado 
                                        ? (reminderSetting.horaNotificacion ?? 'Toca para fijar hora')
                                        : 'Desactivado',
                                    icon: Icons.schedule,
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
                              
                              // --- SECCIÓN 2: OTRAS ALERTAS ---
                              if (generalSettings.isNotEmpty)
                                FadeInDown(
                                  delay: const Duration(milliseconds: 200),
                                  child: SectionHeader(
                                    title: 'Alertas y Actividad', 
                                    icon: Icons.campaign_outlined, 
                                    colors: colors
                                  )
                                ),
                              
                              ...List.generate(generalSettings.length, (index) {
                                final setting = generalSettings[index];
                                return FadeInDown(
                                  delay: Duration(milliseconds: 300 + (index * 100)),
                                  child: SettingsSwitchTile(
                                    title: setting.nombreTipo,
                                    subtitle: setting.descripcion ?? 'Activar o desactivar esta alerta',
                                    // TODO: Mapear un ícono basado en setting.nombreTipo
                                    icon: Icons.notifications_active_outlined, 
                                    dynamicColor: dynamicColor,
                                    initialValue: setting.habilitado,
                                    onChanged: (newValue) {
                                      ref.read(notificationSettingsProvider.notifier)
                                          .updateEnabled(setting.preferenciaId, newValue);
                                    },
                                  ),
                                );
                              }),
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
}

// ... (El shimmer se queda igual) ...
class _NotificationsLoadingShimmer extends StatelessWidget {
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