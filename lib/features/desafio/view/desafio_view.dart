// features/desafio/presentation/views/desafio_view.dart
// ¡VISTA FUSIONADA!

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Importaciones de DESAFÍO ---
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';

// --- Importaciones de BÚSQUEDA ---
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/amigos/model/search_model.dart';

// --- ¡Importamos los widgets de la otra vista! ---
// (Asegúrate de haber hecho públicas SearchField y EmptyState en este archivo)
import 'package:kitsucode/features/amigos/view/search_view.dart';

// -------------------------------------------------------------------
// PROVIDERS DE BÚSQUEDA (Los definimos aquí)
// -------------------------------------------------------------------

final userSearchQueryProvider = StateProvider<String>((ref) => '');

final userSearchResultsProvider = FutureProvider<List<UserSearchPreviewModel>>((
  ref,
) async {
  final query = ref.watch(userSearchQueryProvider);
  if (query.trim().isEmpty) {
    return [];
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.searchUsers(query);
});

// -------------------------------------------------------------------
// VISTA FUSIONADA
// -------------------------------------------------------------------

class DesafioBusquedaView extends ConsumerWidget {
  const DesafioBusquedaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos los providers de AMBAS vistas
    final desafiosAsync = ref.watch(desafiosProvider);
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos y Usuarios')),
      body: CustomScrollView(
        slivers: [
          // --- SECCIÓN 1: DESAFÍO (Arriba) ---
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: desafiosAsync.when(
              data: (data) {
                if (data.agrupador != null) {
                  return SliverToBoxAdapter(
                    child: ExpandableSpecialEventCard(
                      evento: data.agrupador!,
                      desafiosMensuales: data.individuales,
                      completedRetoIds: data.completedRetoIds,
                      isParentCompleted: data.isParentCompleted,
                    ),
                  );
                }
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        '🎉 No hay un evento especial mensual activo en este momento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ),

          // --- SECCIÓN 2: CAMPO DE BÚSQUEDA (En medio) ---
          // ¡Llamamos al widget importado!
          const SliverToBoxAdapter(child: SearchField()),

          // --- SECCIÓN 3: RESULTADOS DE BÚSQUEDA (Abajo) ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: searchResults.when(
              loading: () {
                if (currentQuery.isEmpty) {
                  // ¡Llamamos al widget importado!
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.search,
                      message: 'Busca usuarios por nombre o @usuario',
                    ),
                  );
                }
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error al buscar: $err')),
              ),
              data: (users) {
                if (currentQuery.isEmpty) {
                  // ¡Llamamos al widget importado!
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.search,
                      message: 'Busca usuarios por nombre o @usuario',
                    ),
                  );
                }
                if (users.isEmpty) {
                  // ¡Llamamos al widget importado!
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.person_search,
                      message:
                          'No se encontraron usuarios para "$currentQuery"',
                    ),
                  );
                }

                // La cuadrícula usa el widget 'UserSearchCard' importado
                return SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    // ¡Llamamos al widget importado!
                    return UserSearchCard(user: users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
