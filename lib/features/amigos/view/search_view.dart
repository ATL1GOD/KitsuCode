// lib/features/amigos/view/widgets/search_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/amigos/model/search_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';

// Provider para el término de búsqueda
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider que ejecuta la búsqueda
final userSearchResultsProvider = FutureProvider<List<UserSearchPreviewModel>>((
  ref,
) async {
  final query = ref.watch(userSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repository = ref.watch(profileRepositoryProvider);
  return repository.searchUsers(query);
});

// --- 🔥 BARRA DE BÚSQUEDA REDISEÑADA (ESTILO JUGUETÓN) 🔥 ---
class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(userSearchQueryProvider),
    );
    // Escuchar cambios de foco para animar
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Paleta de colores "Playful"
    final Color colorFondo = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color colorBordeActivo = const Color(0xFF6C63FF); // Morado vibrante
    final Color colorBordeInactivo = Colors.transparent;
    final Color colorIconoBg = const Color(0xFF00C853); // Verde brillante
    final Color colorBoton = const Color(0xFFFFD600); // Amarillo "Pop"

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack, // Rebote sutil
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(50), // Forma de cápsula total
          border: Border.all(
            color: _isFocused ? colorBordeActivo : colorBordeInactivo,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? colorBordeActivo.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: _isFocused ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            children: [
              // 1. Icono "Burbuja"
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorIconoBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorIconoBg.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // 2. Campo de Texto
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar amigos...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      fontWeight: FontWeight.normal,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (query) {
                    ref.read(userSearchQueryProvider.notifier).state = query;
                    setState(() {});
                  },
                ),
              ),

              // 3. Botón de Limpiar (si hay texto)
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    ref.read(userSearchQueryProvider.notifier).state = '';
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),

              // 4. Botón "Action" Juguetón
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorBoton,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colorBoton.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🦊',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.8),
                      fontWeight:
                          FontWeight.w900, // Extra negrita para estilo cartoon
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
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

// ... (El resto del código: UserSearchCard y EmptyState se mantienen igual) ...
class UserSearchCard extends ConsumerWidget {
  final UserSearchPreviewModel user;
  const UserSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<AvatarModel>? avatarsList = ref
        .watch(currentUserAvatarsProvider)
        .value
        ?.cast<AvatarModel>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (context) => UserProfileModal(
                userId: user.userId,
                rank: user.rank,
                rankLanguageIds: user.rankLanguageIds,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 1. Avatar (Izquierda)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28, // Tamaño más compacto para lista
                    backgroundColor: colors.surfaceContainer,
                    child: ClipOval(
                      child: OptimizedImage(
                        imagePath: getAvatarAssetPathById(
                          user.idAvatarSeleccionado,
                          avatarsList,
                        ),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        enableCache: true,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // 2. Información (Centro)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.nombrePerfil,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.nombreUsuario}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Icono de acción o Rango (Derecha)
                // Opcional: Mostrar un pequeño indicador o flecha
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final Widget iconWidget;
  final String? message;
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
