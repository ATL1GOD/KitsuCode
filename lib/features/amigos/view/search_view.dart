// lib/features/search/view/user_search_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
// ¡Importamos el nuevo modelo!
import 'package:kitsucode/features/amigos/model/search_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
// -------------------------------------------------------------------
// PROVIDERS DE BÚSQUEDA (CONECTADOS)
// -------------------------------------------------------------------

// 1. Provider para el término de búsqueda (lo que el usuario escribe)
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// 2. Provider que "ejecuta" la búsqueda
//    (¡Ahora llama al repositorio real!)
final userSearchResultsProvider = FutureProvider<List<UserSearchPreviewModel>>((
  ref,
) async {
  final query = ref.watch(userSearchQueryProvider);

  // Si no hay búsqueda, no devolvemos nada
  if (query.trim().isEmpty) {
    return [];
  }

  // ¡Llamada real al repositorio!
  final repository = ref.watch(profileRepositoryProvider);
  return repository.searchUsers(query);
});

// -------------------------------------------------------------------
// VISTA DE BÚSQUEDA
// -------------------------------------------------------------------

class UserSearchView extends ConsumerWidget {
  const UserSearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(userSearchResultsProvider);
    final currentQuery = ref.watch(userSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Usuarios')),
      body: Column(
        children: [
          // 1. El campo de búsqueda
          const SearchField(),

          // 2. Los resultados
          Expanded(
            child: searchResults.when(
              // ¡Añadimos un estado para refrescar!
              // Cuando el query está vacío, FutureProvider está en 'data' (lista vacía)
              // pero cuando escribes, pasa a 'loading'
              loading: () {
                // Si el query está vacío, no es una carga, es el estado inicial
                if (currentQuery.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    message: 'Busca usuarios por nombre o @usuario',
                  );
                }
                // Si hay query, SÍ estamos cargando
                return const Center(child: CircularProgressIndicator());
              },
              error: (err, stack) =>
                  Center(child: Text('Error al buscar: $err')),
              data: (users) {
                // Si la búsqueda está vacía (al inicio)
                if (currentQuery.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    message: 'Busca usuarios por nombre o @usuario',
                  );
                }
                // Si no hay resultados
                if (users.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search,
                    message: 'No se encontraron usuarios para "$currentQuery"',
                  );
                }

                // 3. La cuadrícula de "cartas"
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Dos columnas
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7, // Ratio similar a una carta de tarot
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    // ¡Usamos el nuevo modelo!
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

// -------------------------------------------------------------------
// WIDGET: CAMPO DE BÚSQUEDA
// -------------------------------------------------------------------

class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(userSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider para resetear el texto si se limpia desde otro lugar
    ref.listen(userSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Buscar por @usuario o nombre...',
          prefixIcon: const Icon(Icons.search),
          // Botón para limpiar
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    // Limpia el controlador y el provider
                    _controller.clear();
                    ref.read(userSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        // Actualiza el provider "en vivo" mientras escribes
        onChanged: (query) {
          ref.read(userSearchQueryProvider.notifier).state = query;
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: CARTA DE USUARIO (EL DISEÑO DE TARJETA)
// -------------------------------------------------------------------

class UserSearchCard extends StatelessWidget {
  // ¡Actualizado para usar el modelo ligero!
  final UserSearchPreviewModel user;
  const UserSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Para que la imagen no se salga
      child: InkWell(
        onTap: () {
          // Llama al modal que ya tenías hecho.
          // Solo necesita el userId, que nuestro modelo SÍ tiene.
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (context) => UserProfileModal(userId: user.userId),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fondo: La imagen de la carta
            SvgPicture.asset(
              // <-- 2. REEMPLAZA Image.asset
              'images/mensual/fondo.svg', // <-- Asegúrate que la ruta termine en .svg
              fit: BoxFit.cover,
            ),

            // 2. Capa de oscurecimiento para legibilidad
            Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.40)),
            ),

            // 3. Contenido del usuario
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(
                      getAvatarAssetPathById(user.idAvatarSeleccionado),
                    ),
                    backgroundColor: colors.surfaceContainer,
                  ),
                  const SizedBox(height: 16),

                  // Nombre de Perfil
                  Text(
                    user.nombrePerfil,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Nombre de Usuario
                  Text(
                    '@${user.nombreUsuario}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      shadows: const [
                        Shadow(blurRadius: 2, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET: ESTADO VACÍO
// -------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Para evitar overflow si el teclado está abierto
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
