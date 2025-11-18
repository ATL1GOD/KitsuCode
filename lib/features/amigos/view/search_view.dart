// lib/features/amigos/view/widgets/search_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/amigos/model/search_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ✅ OptimizedImage para cargar el avatar (asset o remoto)
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

// Provider para el término de búsqueda (lo que el usuario escribe)
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider que "ejecuta" la búsqueda
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
    ref.listen(userSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    final colors = Theme.of(context).colorScheme;
    // Colores inspirados en tu imagen
    final Color colorVerdeOscuro =
        Colors.green.shade800; // O el color que prefieras
    final Color colorCrema = const Color(0xFFF5F3E5);
    final Color colorAmarillo = Colors.yellow.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // 1. Contenedor principal (fondo crema, bordes redondeados)
      child: Container(
        decoration: BoxDecoration(
          color: colorCrema,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        // 2. Usamos ClipRRect para forzar a los hijos a tener bordes redondeados
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3. Parte 1: El contenedor del icono
              // (La versión con ángulo es muy compleja, usamos un rectángulo)
              Container(
                color: colorVerdeOscuro,
                padding: const EdgeInsets.all(12.0),
                child: Icon(Icons.search, color: Colors.white),
              ),

              // 4. Parte 2: El campo de texto (expandido)
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Encuentra nuevos amigos...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colors.surface.withOpacity(0.9) // Color más visible en tema oscuro
                          : colors.onSurface.withOpacity(0.6), // Color en tema claro
                    ),
                    // Aquí tu lógica de 'X' funciona perfectamente
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            onPressed: () {
                              _controller.clear();
                              ref.read(userSearchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,

                    // Quitamos todos los bordes y el fondo
                    filled: false,
                    border: InputBorder.none, //
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,

                    // Ajustamos el padding interno
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                  ),
                  onChanged: (query) {
                    ref.read(userSearchQueryProvider.notifier).state = query;
                    setState(() {});
                  },
                ),
              ),

              // 5. Parte 3: El botón de "Search"
              SizedBox(
                height: 56, // Ajusta a la altura del TextField
                child: ElevatedButton(
                  onPressed: () {
                    // Opcional: puedes forzar la búsqueda aquí si lo deseas
                    // o simplemente dejar que sea decorativo.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorAmarillo,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Sin bordes
                    ),
                  ),
                  child: const Text(
                    'Amigos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserSearchCard extends StatelessWidget {
  // ¡Actualizado para usar el modelo ligero!
  final UserSearchPreviewModel user;
  const UserSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 5,
      shadowColor: Colors.black.withAlpha(77), // (era withOpacity(0.3))
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Para que la imagen no se salga
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withAlpha(128),
            builder: (context) => UserProfileModal(
              userId: user.userId,
              rank: user.rank,
              rankLanguageIds: user.rankLanguageIds, // <-- ¡AÑADIDO!
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset('assets/images/mensual/fondo.svg', fit: BoxFit.cover),

            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
              ), // (era withOpacity(0.40))
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Avatar con OptimizedImage (soporta asset o remoto)
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.surfaceContainer,
                    child: ClipOval(
                      child: OptimizedImage(
                        imagePath: getAvatarAssetPathById(user.idAvatarSeleccionado),
                        width: 80,          // 🔴 requerido por OptimizedImage
                        height: 80,         // 🔴 requerido por OptimizedImage
                        fit: BoxFit.cover,
                        enableCache: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  Text(
                    '@${user.nombreUsuario}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // --- ADVERTENCIA CORREGIDA ---
                      color: Colors.white.withAlpha(
                        204,
                      ), // (era withOpacity(0.8))
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

class EmptyState extends StatelessWidget {
  final Widget iconWidget;
  final String? message; //
  const EmptyState({super.key, required this.iconWidget, this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        iconWidget,
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            message ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
