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
      // 2. ¡CAMBIO! Usamos Column en lugar de CustomScrollView
      body: Column(
        children: [
          // --- SECCIÓN 1: DESAFÍO (Arriba) ---
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 50,
              right: 10,
              bottom: 8,
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
                    // (Dejamos este como estaba, puedes aplicar el mismo
                    // cambio que en el bloque 'data' si lo deseas)
                    // return EmptyState(
                    //   iconWidget: SizedBox(
                    //     width: 250,
                    // ...
                    //   ),
                    //   message: 'Busca usuarios por nombre o @usuario',
                    // );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                error: (err, stack) =>
                    Center(child: Text('Error al buscar: $err')),
                data: (users) {
                  if (currentQuery.isEmpty) {
                    //si no hay búsqueda activa
                    // --- ¡CAMBIO SOLICITADO (2 de 2)! ---
                    // Usamos Expanded y Stack para que el SVG llene el espacio.
                    return EmptyState(
                      iconWidget: Expanded(
                        // <-- CAMBIO: De SizedBox a Expanded
                        child: Padding(
                          // Añadimos padding para que el SVG no toque los bordes
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // // SVG 1 (Título - puedes descomentar y ajustar)
                              // Positioned(
                              //   top: 20, // Ajusta la posición
                              //   child: SvgPicture.asset(
                              //     'images/mensual/amigos2.svg', // <-- ¡RUTA A TU TÍTULO!
                              //     width: 300,
                              //     fit: BoxFit.contain,
                              //   ),
                              // ),

                              // SVG 2 (Imagen Principal - llenará el espacio)
                              // Usamos Positioned.fill para que ocupe todo el Stack
                              // 'fit: BoxFit.contain' asegura que no se corte
                              Positioned.fill(
                                child: SvgPicture.asset(
                                  'images/mensual/amigos4.svg', // <-- Tu imagen principal
                                  fit: BoxFit
                                      .contain, // BoxFit.contain para que no se distorsione
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
