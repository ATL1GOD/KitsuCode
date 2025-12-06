import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';
import 'package:kitsucode/features/amigos/view/search_view.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';
import 'package:kitsucode/shared/widgets/static_settings_background.dart';
import 'package:kitsucode/shared/elastic_list_view/flutter_elastic_list_view.dart';

class DesafioBusquedaView extends ConsumerWidget {
  const DesafioBusquedaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    final colors = Theme.of(context).colorScheme;
    final currentAuthUserId = ref
        .watch(authStateProvider)
        .value
        ?.session
        ?.user
        .id;

    if (currentAuthUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Error de autenticación")),
      );
    }

    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          Scaffold(body: Center(child: Text('Error al cargar perfil: $e'))),
      data: (profile) {
        return Scaffold(
          backgroundColor: colors.surfaceContainerLowest,

          body: Stack(
            children: [
              StaticSettingsBackground(profile: profile, colors: colors),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        top: 10,
                        right: 10,
                      ),
                      child: desafiosAsync.when(
                        data: (data) {
                          if (data.agrupador != null) {
                            return ExpandableSpecialEventCard(
                              evento: data.agrupador!,
                              desafiosMensuales: data.individuales,
                              completedRetoIds: data.completedRetoIds,
                              isParentCompleted: data.isParentCompleted,
                            );
                          }
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                '🎉 No hay un evento especial mensual activo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                      ),
                    ),

                    const SearchField(),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: searchResults.when(
                          loading: () {
                            if (currentQuery.isEmpty) {}
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          error: (err, stack) =>
                              Center(child: Text('Error al buscar: $err')),
                          data: (users) {
                            if (currentQuery.isEmpty) {
                              return EmptyState(
                                iconWidget: Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),

                                    child: OptimizedImage(
                                      imagePath:
                                          'assets/images/banner/amigos.webp',
                                      isLocalAsset: true,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (users.isEmpty) {
                              return EmptyState(
                                iconWidget: Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                message:
                                    'No se encontraron usuarios para "$currentQuery"',
                              );
                            }

                            return ElasticListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              itemCount: users.length,

                              elasticityFactor: 4,

                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),

                              itemBuilder: (context, index) {
                                return UserSearchCard(user: users[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
