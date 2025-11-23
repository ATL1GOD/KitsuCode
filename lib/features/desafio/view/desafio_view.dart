// lib/features/desafio/view/desafio_view.dart (o donde lo tengas)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';
import 'package:kitsucode/features/amigos/view/search_view.dart';

// --- NUEVO: Imports necesarios para el fondo (copiados de tu ejemplo) ---
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/widgets/static_settings_background.dart';

class DesafioBusquedaView extends ConsumerWidget {
  const DesafioBusquedaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    // --- NUEVO: Obtener perfil y colores (igual que en SupportView) ---
    final colors = Theme.of(context).colorScheme;
    final currentAuthUserId = ref
        .watch(authStateProvider)
        .value
        ?.session
        ?.user
        .id;

    // --- NUEVO: Check de autenticación ---
    if (currentAuthUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Error de autenticación")),
      );
    }

    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    // --- MODIFICADO: Envolvemos todo en el profileState.when ---
    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          Scaffold(body: Center(child: Text('Error al cargar perfil: $e'))),
      data: (profile) {
        // --- El Scaffold original ahora está dentro del 'data' ---
        return Scaffold(
          // --- NUEVO: Fondo base para el degradado (igual que SupportView) ---
          backgroundColor: colors.surfaceContainerLowest,

          // --- MODIFICADO: El body es un Stack ---
          body: Stack(
            children: [
              // --- FONDO ESTÁTICO (igual que SupportView) ---
              StaticSettingsBackground(profile: profile, colors: colors),

              // --- CONTENIDO (envuelto en SafeArea) ---
              SafeArea(
                child: Column(
                  // <-- El Column original
                  children: [
                    Padding(
                      // --- MODIFICADO: Padding superior reducido (SafeArea se encarga) ---
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

                    // --- Sin cambios ---
                    const SearchField(),

                    // --- Sin cambios ---
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
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: SvgPicture.asset(
                                            'assets/images/mensual/amigos4.svg',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
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

                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: users.length,
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
