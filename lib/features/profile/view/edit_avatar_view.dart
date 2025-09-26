import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:animate_do/animate_do.dart'; 

enum AvatarCategory { general, exclusive }

class EditAvatarView extends ConsumerStatefulWidget {
  final String currentAvatar;
  const EditAvatarView({super.key, required this.currentAvatar});

  @override
  ConsumerState<EditAvatarView> createState() => _EditAvatarViewState();
}

class _EditAvatarViewState extends ConsumerState<EditAvatarView> {
  final List<String> _generalAvatars = [
    'assets/images/login_zorro.png', 
    'assets/images/avatar_mono.png',
    'assets/images/avatar_tiburon.png',
    // ...
  ];

  final List<String> _exclusiveAvatars = [
    'assets/images/avatar_leon.png',
    'assets/images/login_zorro.png', 
    'assets/images/avatar_mono.png',
    'assets/images/avatar_tiburon.png',
  ];
  
  //Lista para identificar avatares que necesitan fondo
  final Set<String> _transparentAvatars = {
    'assets/images/login_zorro.png',
  };

  late String _selectedAvatar;
  AvatarCategory _selectedCategory = AvatarCategory.general;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentAvatar;
  }

  List<String> get _currentAvatarList {
    return _selectedCategory == AvatarCategory.general ? _generalAvatars : _exclusiveAvatars;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryDarkColorScheme.primary, primaryLightColorScheme.primaryFixed],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Barra de navegación 
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4F4F4F)),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Editar avatar',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4F4F4F)),
                      ),
                      ElevatedButton(
  onPressed: () => context.pop(_selectedAvatar),
  style: ElevatedButton.styleFrom(
    backgroundColor: colors.primaryContainer, // Color de fondo del tema
    foregroundColor: colors.onPrimaryContainer, // Color del texto del tema
    elevation: 2, // Una pequeña sombra para darle profundidad
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), // Bordes redondeados
      side: BorderSide(
        color: colors.secondary.withOpacity(0.8), // Borde con el color naranja
        width: 1.5,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  ),
  child: const Text(
    'Ok',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Avatar principal 
              FadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: _buildAvatarWithBackground(
                  avatarPath: _selectedAvatar,
                  size: 160,
                  colors: colors,
                ),
              ),
              const SizedBox(height: 30),

              // --- Pestañas con animación 
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryTab(icon: Icons.pets, category: AvatarCategory.general, colors: colors),
                    const SizedBox(width: 20),
                    _buildCategoryTab(icon: Icons.star_border_purple500_outlined, category: AvatarCategory.exclusive, colors: colors),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Grid de avatares
              Expanded(
                child: FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _currentAvatarList.length,
                      itemBuilder: (context, index) {
                        final avatarPath = _currentAvatarList[index];
                        final isSelected = avatarPath == _selectedAvatar;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = avatarPath),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? colors.secondary : colors.primary.withOpacity(0.5),
                                width: isSelected ? 3.0 : 1.5,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: colors.secondary.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)] : [],
                            ),
                            child: _buildAvatarWithBackground(
                              avatarPath: avatarPath,
                              size: 80, 
                              colors: colors,
                              isGridItem: true,
                            ),
                          ),
                        );
                      },
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

  //Widget reutilizable para mostrar avatares con o sin fondo
  Widget _buildAvatarWithBackground({
    required String avatarPath,
    required double size,
    required ColorScheme colors,
    bool isGridItem = false,
  }) {
    final needsBackground = _transparentAvatars.contains(avatarPath);
    
    Widget avatarImage = ClipRRect(
      borderRadius: BorderRadius.circular(isGridItem ? 28.0 : 48.0),
      child: Image.asset(avatarPath, width: size, height: size, fit: BoxFit.cover),
    );

    if (needsBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Padding(
          
          padding: EdgeInsets.all(size * 0.1), 
          child: avatarImage,
        ),
      );
    }
    return avatarImage;
  }

  Widget _buildCategoryTab({required IconData icon, required AvatarCategory category, required ColorScheme colors}) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : colors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? null : Border.all(color: colors.primaryContainer.withOpacity(0.5)),
        ),
        child: Icon(icon, color: colors.secondary),
      ),
    );
  }
}