// lib/features/profile/view/challenge_history_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart'; // Importa el authProvider
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart'; // Importa los providers de perfil
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:lottie/lottie.dart';

// Importa el nuevo modelo y el tile que crearemos
import 'package:kitsucode/features/profile/model/challenge_history_model.dart';
import 'widgets/challenge_history_tile.dart';

class ChallengeHistoryView extends ConsumerWidget {
  const ChallengeHistoryView({super.key});

  // Lógica para el color dinámico (copiada de AllStatsView)
  static Color getHeaderColor(UserProfileModel userProfile, ColorScheme colors) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtenemos el ID del usuario actual (corrige error 'authProvider')
    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    // Obtenemos el perfil para el color dinámico (corrige error 'profileProvider')
    final profileState = ref.watch(userProfileByIdProvider(currentUserId));
    // Obtenemos el nuevo historial
    final historyState = ref.watch(challengeHistoryProvider(currentUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()), // Shimmer simple
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          // Color dinámico basado en el avatar
          final dynamicColor = getHeaderColor(profile, colors);

          return Stack(
            children: [
              // Gradiente de fondo (copiado de AllStatsView)
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

              // Animación Lottie de fondo (copiada de AllStatsView)
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

              // Contenido principal
              SafeArea(
                child: Column(
                  children: [
                    // AppBar personalizada (copiada de AllStatsView)
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
                                border: Border.all(color: colors.outlineVariant.withAlpha(130)),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Historial de Retos', // <-- Título
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_month_outlined, color: colors.onSurface),
                            onPressed: () async {
                              final now = DateTime.now();
                              // Define el rango seleccionable (ej. 1 año atrás)
                              final firstDate = DateTime(now.year - 1, now.month, now.day);
                              // Obtiene el rango actual para pre-seleccionarlo
                              final currentRange = ref.read(historyDateRangeProvider);

                              final newRange = await showDateRangePicker(
                                context: context,
                                firstDate: firstDate,
                                lastDate: now,
                                initialDateRange: currentRange,
                              );

                              if (newRange != null) {
                                // 1. Actualiza el provider de rango
                                ref.read(historyDateRangeProvider.notifier).state = newRange;
                                // 2. Refresca manualmente el provider de datos
                                ref.refresh(challengeHistoryProvider(currentUserId).future);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Lista del historial
                    Expanded(
                      child: historyState.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error al cargar historial: $e')),
                        data: (history) {
                          if (history.isEmpty) {
                            return const Center(
                              child: Text(
                                'Sin retos completados en los últimos 30 días.',
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          }

                          // La lista
                          return ListView.builder(
                            padding: EdgeInsets.only(
                              top: 20, // Espacio desde el appbar
                              bottom: MediaQuery.of(context).padding.bottom + 20,
                              left: 16,
                              right: 16,
                            ),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return ChallengeHistoryTile(item: item); // Usamos el Tile del Paso 5
                            },
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