import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/notifications/provider/notification_settings_provider.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart'; 
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

// Esta vista es genérica. Recibe un título y una lista de settings.
class NotificationCategoryView extends ConsumerWidget {
  final String title;
  final List<NotificationSetting> settings;

  const NotificationCategoryView({
    super.key, 
    required this.title,
    required this.settings
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtenemos el perfil solo para el color dinámico del fondo
    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    // Usamos el color del perfil o un color de fallback
    final dynamicColor = profileState.value != null 
      ? AllStatsView.getHeaderColor(profileState.value!, colors)
      : colors.primary;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          // --- FONDO y LOTTIE (Idéntico a las otras vistas) ---
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
                // --- BARRA SUPERIOR (Idéntica) ---
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
                          title, // <-- Usamos el título que nos pasaron
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- LISTA DE SWITCHES ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    children: [
                      ...List.generate(settings.length, (index) {
                        final setting = settings[index];
                        return FadeInDown(
                          delay: Duration(milliseconds: 100 + (index * 100)),
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