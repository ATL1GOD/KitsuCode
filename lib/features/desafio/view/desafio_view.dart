import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Importaciones de DESAFÍO ---
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';

// ¡Importamos el archivo que contiene los widgets de búsqueda!
import 'package:kitsucode/features/amigos/view/search_view.dart';
// -------------------------------------------------------------------
// PROVIDERS DE BÚSQUEDA
// (Los definimos aquí para que esta vista los controle)
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// VISTA FUSIONADA
// -------------------------------------------------------------------

class DesafioBusquedaView extends ConsumerWidget {
  const DesafioBusquedaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observamos los providers de AMBAS vistas
    final desafiosAsync = ref.watch(desafiosProvider);
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos y Usuarios')),
      // 2. ¡CAMBIO! Usamos Column en lugar de CustomScrollView
      body: Column(
        children: [
          // --- SECCIÓN 1: DESAFÍO (Arriba) ---
          // ¡CAMBIO! Usamos Padding normal, no SliverPadding
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // ¡CAMBIO! El .when() va directo, no dentro de un 'sliver:'
            child: desafiosAsync.when(
              data: (data) {
                // Si hay reto, muestra la tarjeta
                if (data.agrupador != null) {
                  // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                  return ExpandableSpecialEventCard(
                    evento: data.agrupador!,
                    desafiosMensuales: data.individuales,
                    completedRetoIds: data.completedRetoIds,
                    isParentCompleted: data.isParentCompleted,
                  );
                }
                // Mensaje si no hay reto
                // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      '🎉 No hay un evento especial mensual activo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                );
              },
              // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          // --- SECCIÓN 2: CAMPO DE BÚSQUEDA (En medio) ---
          // ¡CAMBIO! Usamos el widget directamente, sin SliverToBoxAdapter
          const SearchField(),

          // --- SECCIÓN 3: RESULTADOS DE BÚSQUEDA (Abajo) ---
          // ¡CAMBIO CLAVE! Usamos Expanded para que ocupe el resto de la pantalla
          Expanded(
            // ¡CAMBIO! Usamos Padding normal, no SliverPadding
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              // ¡CAMBIO! El .when() va directo, no dentro de un 'sliver:'
              child: searchResults.when(
                loading: () {
                  if (currentQuery.isEmpty) {
                    // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                    return const EmptyState(
                      icon: Icons.search,
                      message: 'Busca usuarios por nombre o @usuario',
                    );
                  }
                  // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                  return const Center(child: CircularProgressIndicator());
                },
                error: (err, stack) =>
                    // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                    Center(child: Text('Error al buscar: $err')),
                data: (users) {
                  if (currentQuery.isEmpty) {
                    // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                    return const EmptyState(
                      icon: Icons.search,
                      message: 'Busca usuarios por nombre o @usuario',
                    );
                  }
                  if (users.isEmpty) {
                    // ¡CAMBIO! Retornamos el widget directamente, sin SliverToBoxAdapter
                    return EmptyState(
                      icon: Icons.person_search,
                      message:
                          'No se encontraron usuarios para "$currentQuery"',
                    );
                  }

                  // ¡CAMBIO! Convertimos SliverGrid en GridView.builder
                  // GridView.builder SÍ sabe cómo funcionar dentro de un Expanded.
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
                      // ¡Llamamos al widget importado!
                      return UserSearchCard(user: users[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
