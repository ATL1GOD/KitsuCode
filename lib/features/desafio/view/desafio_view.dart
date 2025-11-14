import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';
import 'package:kitsucode/features/amigos/view/search_view.dart';

class DesafioBusquedaView extends ConsumerWidget {
  const DesafioBusquedaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 50, right: 10),
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

          const SearchField(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: searchResults.when(
                loading: () {
                  if (currentQuery.isEmpty) {}
                  return const Center(child: CircularProgressIndicator());
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
    );
  }
}
