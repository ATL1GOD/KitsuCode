// lib/features/profile/view/edit_avatar_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/features/profile/provider/profile_controller.dart';

class EditAvatarView extends ConsumerStatefulWidget {
  final String currentAvatar;
  const EditAvatarView({super.key, required this.currentAvatar});

  @override
  ConsumerState<EditAvatarView> createState() => _EditAvatarViewState();
}

class _EditAvatarViewState extends ConsumerState<EditAvatarView> {
  final List<String> _avatars = [
    'assets/images/login_zorro.png',
    'assets/images/avatar_mono.png',
    'assets/images/login_zorro.png',
    'assets/images/avatar_placeholder.png',
    'assets/images/login_zorro.png',
    'assets/images/avatar_placeholder.png',
    'assets/images/login_zorro.png',
    'assets/images/avatar_placeholder.png',
    'assets/images/login_zorro.png',
    'assets/images/avatar_placeholder.png',
  ];

  late String _selectedAvatar;

   @override
  void initState() {
    super.initState();
    // 2. El avatar seleccionado inicialmente es el que recibimos de la pantalla anterior
    _selectedAvatar = widget.currentAvatar;
  }

  // --- FUNCIÓN DE NAVEGACIÓN SEGURA ---
  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile'); // Si no puede regresar, lo mandamos al perfil
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSaving = ref.watch(profileControllerProvider);

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
              // --- Barra de navegación superior ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4F4F4F)),
                       onPressed: () => context.pop(), // Usamos la función segura
                    ),
                    Text(
                      'Editar avatar',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4F4F4F)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Regresa y DEVUELVE la ruta del avatar seleccionado
                        context.pop(_selectedAvatar); 
                      },
                      child: isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.secondary),
                            )
                          : Text(
                              'Ok',
                              style: TextStyle(
                                color: colors.secondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // ... (El resto del código no necesita cambios)
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38.0),
                  child: Image.asset(
                    _selectedAvatar,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryTab(iconData: Icons.pets, isSelected: true, colors: colors),
                  const SizedBox(width: 20),
                  _buildCategoryTab(iconData: Icons.new_releases_outlined, isSelected: false, colors: colors),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final avatarPath = _avatars[index];
                      final isSelected = avatarPath == _selectedAvatar;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatarPath;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: isSelected ? colors.secondary : colors.primary,
                              width: isSelected ? 4.0 : 2.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colors.secondary.withOpacity(0.7),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32.0),
                            child: Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para crear las pestañas de categoría
  Widget _buildCategoryTab({required IconData iconData, required bool isSelected, required ColorScheme colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: colors.primary.withOpacity(0.5)),
      ),
      child: Icon(iconData, color: isSelected ? colors.onPrimaryContainer : colors.primary),
    );
  }
}