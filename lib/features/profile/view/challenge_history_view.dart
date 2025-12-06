import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

import 'widgets/challenge_history_tile.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:kitsucode/shared/widgets/static_settings_background.dart';

class ChallengeHistoryView extends ConsumerWidget {
  const ChallengeHistoryView({super.key});

  static Color getHeaderColor(
    UserProfileModel userProfile,
    ColorScheme colors,
  ) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    final profileState = ref.watch(userProfileByIdProvider(currentUserId));

    final historyState = ref.watch(challengeHistoryProvider(currentUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          getHeaderColor(profile, colors);

          return Stack(
            children: [
              StaticSettingsBackground(profile: profile, colors: colors),

              /* --- CÓDIGO ELIMINADO ---
               
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

               
               ColorFiltered(
                 colorFilter: ColorFilter.mode(
                   colors.secondaryFixedDim.withAlpha(204),
                   BlendMode.srcIn,
                 ),
                 child: Lottie.asset(
                   'assets/animations/spring.json',
                   width: double.infinity,
                   height: double.infinity,
                   fit: BoxFit.cover,
                 ),
               ),
               --- FIN CÓDIGO ELIMINADO --- */
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
                              'Historial de Retos',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.calendar_month_outlined,
                              color: colors.onSurface,
                            ),
                            onPressed: () async {
                              final now = DateTime.now();

                              final firstDate = DateTime(
                                now.year - 1,
                                now.month,
                                now.day,
                              );

                              final currentRange = ref.read(
                                historyDateRangeProvider,
                              );

                              final newRange = await showDateRangePicker(
                                context: context,
                                firstDate: firstDate,
                                lastDate: now,
                                initialDateRange: currentRange,
                              );

                              if (newRange != null) {
                                ref
                                        .read(historyDateRangeProvider.notifier)
                                        .state =
                                    newRange;

                                // ignore: unused_result
                                ref.refresh(
                                  challengeHistoryProvider(
                                    currentUserId,
                                  ).future,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: historyState.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(
                          child: Text('Error al cargar historial: $e'),
                        ),
                        data: (history) {
                          if (history.isEmpty) {
                            return const Center(
                              child: Text(
                                'Sin retos completados en este rango de fechas, unicamente puedes ver tus retos completados en un rango de 30 días.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          }

                          return ListView.builder(
                            cacheExtent: 200.0,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                            padding: EdgeInsets.only(
                              top: 20,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 20,
                              left: 16,
                              right: 16,
                            ),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];

                              return ChallengeHistoryTile(item: item)
                                  .animate()
                                  .fadeIn(
                                    delay: (100 * (index % 10)).ms,
                                    duration: 500.ms,
                                  )
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  );
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
