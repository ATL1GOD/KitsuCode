import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart';
import 'package:lottie/lottie.dart';

// Esta vista es un placeholder que sigue el diseño
class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- FONDO ---
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
              // --- ANIMACIÓN LOTTIE ---
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.secondaryFixedDim.withOpacity(0.8),
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
                    // --- BARRA SUPERIOR ---
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

                    // --- LISTA DE OPCIONES DE NOTIFICACIÓN ---
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        children: [
                          // A. Recordatorios de Estudio
                          SettingsNavigationTile(
                            title: 'Recordatorios de Estudio',
                            subtitle: 'Programar alertas para practicar',
                            icon: Icons.schedule,
                            dynamicColor: dynamicColor,
                            onTap: () { 
                              // TODO: Navegar a /settings/notifications/recordatorios
                            },
                          ),
                          // B. Amigos y Actividad Social
                          SettingsNavigationTile(
                            title: 'Amigos y Actividad',
                            subtitle: 'Alertas de nuevos seguidores',
                            icon: Icons.people_alt_outlined,
                            dynamicColor: dynamicColor,
                            onTap: () { 
                              // TODO: Navegar a /settings/notifications/amigos
                            },
                          ),
                          // C. Retos y Novedades
                          SettingsNavigationTile(
                            title: 'Retos y Novedades',
                            subtitle: 'Alertas de retos especiales y actualizaciones',
                            icon: Icons.new_releases_outlined,
                            dynamicColor: dynamicColor,
                            onTap: () { 
                              // TODO: Navegar a /settings/notifications/novedades
                            },
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