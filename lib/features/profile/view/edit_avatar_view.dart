import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    'assets/images/avatar_leon.png',
    'assets/images/avatar_gato.png',
    'assets/images/avatar_panda.png',
  ];

  final List<String> _exclusiveAvatars = [
    'assets/images/avatar_leon.png',
    'assets/images/login_zorro.png',
    'assets/images/avatar_mono.png',
    'assets/images/avatar_tiburon.png',
  ];

  final Set<String> _transparentAvatars = {
    'assets/images/login_zorro.png',
  };

  late String _selectedAvatar;
  AvatarCategory _selectedCategory = AvatarCategory.general;

  // Función para obtener el color dinámico basado en el avatar seleccionado
  Color _getDynamicBackgroundColor(ColorScheme colors) {
    final avatar = _selectedAvatar.toLowerCase();
    if (avatar.contains('tiburon')) return const Color(0xFF0097A7); 
    if (avatar.contains('zorro')) return const Color(0xFFE65100); 
    if (avatar.contains('gato')) return const Color(0xFF7B1FA2);
    if (avatar.contains('león') || avatar.contains('leon')) return const Color(0xFFF57F17);
    if (avatar.contains('panda')) return const Color(0xFF2E7D32); 
    // Color por defecto 
    return colors.primary; 
  }

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

    final dynamicBgColor = _getDynamicBackgroundColor(colors);

    return Scaffold(
      body: AnimatedContainer( // Usamos AnimatedContainer para la transición de color del fondo
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colors.inverseSurface, // Color de fondo oscuro principal
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              dynamicBgColor.withOpacity(0.3), // El destello cambia con el avatar
              colors.inverseSurface.withOpacity(0.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
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
                        onPressed: () => context.pop(_selectedAvatar),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 8,
                          shadowColor: colors.secondary.withOpacity(0.6),
                        ),
                        child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  avatarPath: _selectedAvatar,
                  size: 160,
                  needsBackground: _transparentAvatars.contains(_selectedAvatar),
                  dynamicColor: dynamicBgColor, // Pasamos el color dinámico
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
                      isSelected: _selectedCategory == AvatarCategory.general,
                      onTap: () => setState(() => _selectedCategory = AvatarCategory.general),
                    ),
                    const SizedBox(width: 20),
                    _CategoryIconButton(
                      icon: Icons.star_border_purple500_outlined,
                      isSelected: _selectedCategory == AvatarCategory.exclusive,
                      onTap: () => setState(() => _selectedCategory = AvatarCategory.exclusive),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                        return _CircularAvatarCell(
                          avatarPath: avatarPath,
                          isSelected: isSelected,
                          needsBackground: _transparentAvatars.contains(avatarPath),
                          onTap: () => setState(() => _selectedAvatar = avatarPath),
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
}

// --- WIDGETS DE UI ---

class _SelectedAvatarDisplay extends StatelessWidget {
  final String avatarPath;
  final double size;
  final bool needsBackground;
  final Color dynamicColor; // Nuevo: Recibe el color dinámico

  const _SelectedAvatarDisplay({
    required this.avatarPath,
    required this.size,
    required this.needsBackground,
    required this.dynamicColor, // Inicializa el nuevo parámetro
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // --- CAMBIO DE DISEÑO: Borde degradado ahora usa dynamicColor ---
        gradient: LinearGradient(colors: [dynamicColor, colors.primary]),
        boxShadow: [
          BoxShadow(color: dynamicColor.withOpacity(0.7), blurRadius: 25, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval( // Ya no hay Container intermedio oscuro
        child: Container(
          color: needsBackground ? colors.surfaceContainerHighest : Colors.transparent,
          child: Image.asset(avatarPath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryIconButton({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainer.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.secondary : colors.primary.withOpacity(0.3),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected ? [BoxShadow(color: colors.secondary.withOpacity(0.5), blurRadius: 10)] : [],
        ),
        child: Icon(icon, color: isSelected ? colors.onPrimary : colors.onSurfaceVariant, size: 28),
      ),
    );
  }
}

class _CircularAvatarCell extends StatelessWidget {
  final String avatarPath;
  final bool isSelected;
  final bool needsBackground;
  final VoidCallback onTap;

  const _CircularAvatarCell({required this.avatarPath, required this.isSelected, required this.onTap, required this.needsBackground});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.secondary : Colors.transparent,
            width: isSelected ? 4.0 : 0.0,
          ),
          boxShadow: isSelected ? [BoxShadow(color: colors.secondary.withOpacity(0.6), blurRadius: 12)] : [],
        ),
        child: ClipOval(
          child: Container(
            color: needsBackground ? colors.surfaceContainerHighest : Colors.transparent,
            child: Image.asset(avatarPath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}