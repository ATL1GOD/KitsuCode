import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:flutter_svg/flutter_svg.dart';

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
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          // --- SECCIÓN 2: CAMPO DE BÚSQUEDA (En medio) ---
          const SearchField(),

          // --- SECCIÓN 3: RESULTADOS DE BÚSQUEDA (Abajo) ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: searchResults.when(
                loading: () {
                  if (currentQuery.isEmpty) {
                    //si no hay búsqueda activa
                    // --- ¡CAMBIO SOLICITADO (1 de 2)! ---
                    // Usamos un Column para apilar verticalmente
                    // return EmptyState(
                    //   iconWidget: SizedBox(
                    //     width: 250,
                    //     height: 250,
                    //     child: Column(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         // SVG 1 (Tu Título)
                    //         SvgPicture.asset(
                    //           'images/mensual/tu_titulo_svg.svg', // <-- ¡RUTA A TU TÍTULO!
                    //           width: 220,
                    //           height: 50,
                    //           fit: BoxFit.contain,
                    //         ),
                    //         const SizedBox(height: 16),
                    //         // SVG 2 (Tu Imagen)
                    //         SvgPicture.asset(
                    //           'images/mensual/amigos.svg', // <-- Tu imagen principal
                    //           width: 180,
                    //           height: 180,
                    //           fit: BoxFit.contain,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    //   message: 'Busca usuarios por nombre o @usuario',
                    // );
                    // --- FIN DEL CAMBIO ---
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                error: (err, stack) =>
                    Center(child: Text('Error al buscar: $err')),
                data: (users) {
                  if (currentQuery.isEmpty) {
                    //si no hay búsqueda activa
                    // --- ¡CAMBIO SOLICITADO (2 de 2)! ---
                    // Usamos un Column para apilar verticalmente
                    return EmptyState(
                      iconWidget: SizedBox(
                        width: 400,
                        height: 400,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SVG 1 (Tu Título)
                            SvgPicture.asset(
                              'images/mensual/amigos2.svg', // <-- ¡RUTA A TU TÍTULO!
                              width: 300,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 5),
                            // SVG 2 (Tu Imagen)
                            SvgPicture.asset(
                              'images/mensual/amigos.svg', // <-- Tu imagen principal
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      message: 'Busca usuarios por nombre o @usuario',
                    );
                    // --- FIN DEL CAMBIO ---
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
    );
  }
}
