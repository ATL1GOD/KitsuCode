import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/features/profile/view/widgets/avatar_modal.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

enum AvatarCategory { comun, especial }

class EditAvatarView extends ConsumerStatefulWidget {
  final int currentAvatarId;
  const EditAvatarView({super.key, required this.currentAvatarId});

  @override
  ConsumerState<EditAvatarView> createState() => _EditAvatarViewState();
}

class _EditAvatarViewState extends ConsumerState<EditAvatarView> {
  late int _selectedAvatarId;
  AvatarCategory _selectedCategory = AvatarCategory.comun;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
  }

  List<AvatarModel> _getFilteredAvatars(List<AvatarModel> allAvatars) {
    return _selectedCategory == AvatarCategory.comun
        ? allAvatars.where((a) => a.esComun).toList()
        : allAvatars.where((a) => a.esEspecial).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarsAsync = ref.watch(currentUserAvatarsProvider);
    final avatarsValue = avatarsAsync.valueOrNull;

    final dynamicBgColor = avatarsValue != null
        ? getAvatarColorById(_selectedAvatarId, avatarsValue)
        : Colors.grey;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              dynamicBgColor.withAlpha(77),
              colors.inverseSurface.withAlpha(0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colors.onSurface,
                        ),
                        onPressed: () => context.pop(null),
                      ),
                      Text(
                        'Selecciona tu avatar',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.pop(_selectedAvatarId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 8,
                          shadowColor: colors.secondary.withAlpha(153),
                        ),
                        child: const Text(
                          'Listo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              FadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: _SelectedAvatarDisplay(
                  avatarId: _selectedAvatarId,
                  size: 160,
                  dynamicColor: dynamicBgColor,
                ),
              ),
              const SizedBox(height: 30),

              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CategoryIconButton(
                      icon: Icons.pets,
                      isSelected: _selectedCategory == AvatarCategory.comun,
                      onTap: () => setState(
                        () => _selectedCategory = AvatarCategory.comun,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _CategoryIconButton(
                      icon: Icons.star_border_purple500_outlined,
                      isSelected: _selectedCategory == AvatarCategory.especial,
                      onTap: () => setState(
                        () => _selectedCategory = AvatarCategory.especial,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: avatarsAsync.when(
                  data: (avatars) {
                    final filteredAvatars = _getFilteredAvatars(avatars);

                    if (filteredAvatars.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay avatares en esta categoría',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      );
                    }

                    return FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GridView.builder(
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          cacheExtent: 200,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: filteredAvatars.length,
                          itemBuilder: (context, index) {
                            final avatar = filteredAvatars[index];
                            final isSelected = avatar.id == _selectedAvatarId;
                            return _CircularAvatarCell(
                              avatar: avatar,
                              isSelected: isSelected,
                              onTap: () {
                                if (avatar.desbloqueado) {
                                  setState(() => _selectedAvatarId = avatar.id);
                                } else {
                                  AvatarModal.show(context, avatar: avatar);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error al cargar avatares',
                      style: textTheme.bodyLarge?.copyWith(color: colors.error),
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

class _SelectedAvatarDisplay extends ConsumerWidget {
  final int avatarId;
  final double size;
  final Color dynamicColor;

  const _SelectedAvatarDisplay({
    required this.avatarId,
    required this.size,
    required this.dynamicColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final String avatarPath = ref
        .watch(currentUserAvatarsProvider)
        .when(
          data: (avatars) {
            final avatar = avatars.firstWhere(
              (a) => a.id == avatarId,
              orElse: () => avatars.first,
            );
            return avatar.assetPath;
          },
          loading: () => '',
          error: (e, s) => '',
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [dynamicColor, colors.primary]),
        boxShadow: [
          BoxShadow(
            color: dynamicColor.withAlpha(179),
            blurRadius: 25,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Container(
          color: Colors.transparent,
          child: (avatarPath.isEmpty)
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : OptimizedImage(
                  imagePath: avatarPath,
                  fit: BoxFit.cover,
                  enableCache: true,
                  width: size,
                  height: size,
                ),
        ),
      ),
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.surfaceContainer.withAlpha(51),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.secondary : colors.primary.withAlpha(77),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.secondary.withAlpha(128),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}

class _CircularAvatarCell extends StatelessWidget {
  final AvatarModel avatar;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CircularAvatarCell({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLocked = !avatar.desbloqueado;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size,
                  height: size,
                  transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.secondary : Colors.transparent,
                      width: isSelected ? 4.0 : 0.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.secondary.withAlpha(153),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipOval(
                    child: ColorFiltered(
                      colorFilter: isLocked
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Container(
                        color: Colors.transparent,
                        child: OptimizedImage(
                          imagePath: avatar.assetPath,
                          fit: BoxFit.cover,
                          enableCache: true,
                          width: size,
                          height: size,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(128),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: colors.onSurface.withAlpha(204),
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
