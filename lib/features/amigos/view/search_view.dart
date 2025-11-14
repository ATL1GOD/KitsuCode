import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/amigos/model/search_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        onChanged: (query) {
          ref.read(userSearchQueryProvider.notifier).state = query;
        },
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
          print('=================================');
          print('ABRIENDO MODAL PARA: ${user.nombreUsuario}');
          print('RANK: ${user.rank}');
          print('IDs DE LENGUAJE: ${user.rankLanguageIds}');
          print('TIPO DE DATO: ${user.rankLanguageIds.runtimeType}');
          print('=================================');

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
            SvgPicture.asset('images/mensual/fondo.svg', fit: BoxFit.cover),

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
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(
                      getAvatarAssetPathById(user.idAvatarSeleccionado),
                    ),
                    backgroundColor: colors.surfaceContainer,
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
  // --- ¡CAMBIO AQUÍ! ---
  // 'icon' ahora es 'iconWidget' y es de tipo Widget
  final Widget iconWidget;
  // --- FIN DEL CAMBIO ---
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
