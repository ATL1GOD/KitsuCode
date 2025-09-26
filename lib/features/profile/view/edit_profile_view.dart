import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_controller.dart';
import 'package:animate_do/animate_do.dart';

class EditProfileView extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;
  const EditProfileView({super.key, required this.userProfile});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late final TextEditingController _nameController;
  late String _currentAvatar;
  late String _initialName;
  late String _initialAvatar;

  bool get _hasChanges =>
      _nameController.text != _initialName || _currentAvatar != _initialAvatar;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.nombrePerfil);
    _currentAvatar = widget.userProfile.avatarUrl;
    _initialName = widget.userProfile.nombrePerfil;
    _initialAvatar = _currentAvatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleBackNavigation() async {
    if (_hasChanges) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar cambios'),
          content: const Text('¿Seguro que quieres salir sin guardar?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salir')),
          ],
        ),
      ) ?? false;
      if (shouldPop && mounted) context.pop();
    } else {
      context.pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSaving = ref.watch(profileControllerProvider);

    // Lógica para mostrar el avatar de red o local
    Widget avatarImage;
    if (_currentAvatar.startsWith('http')) {
      avatarImage = Image.network(_currentAvatar, fit: BoxFit.cover);
    } else {
      avatarImage = Image.asset(_currentAvatar, fit: BoxFit.cover);
    }

    return Scaffold(
      // Usamos un Stack para poner nuestro fondo personalizado
      body: Stack(
        children: [
          
          const LoginBackground(child: SizedBox.shrink()),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //HEADER CON BOTÓN DE REGRESO Y TÍTULO PERSONALIZADO 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _handleBackNavigation,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surface.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back_ios_new, color: colors.onSurface, size: 20),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Editar Perfil',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 40), // Espacio para centrar el título
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- AVATAR EDITABLE ---
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(color: colors.secondary.withOpacity(0.4), blurRadius: 25, spreadRadius: 1)
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40.0),
                            child: avatarImage,
                          ),
                        ),
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: Swing( // Animación de swing para el botón
                            infinite: true,
                            delay: const Duration(seconds: 2),
                            child: Material(
                              color: colors.surface,
                              elevation: 4,
                              shape: const CircleBorder(),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: colors.secondary,
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: colors.onSecondary, size: 18),
                                  onPressed: () async {
                                    final newAvatar = await context.push<String>('/edit-avatar', extra: _currentAvatar);
                                    if (newAvatar != null) {
                                      setState(() => _currentAvatar = newAvatar);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),

                  // --- TARJETA DEL FORMULARIO DE EDICIÓN ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      
                      child: Card(
                        color: colors.surface.withOpacity(0.8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: colors.primaryContainer.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(25)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Nombre de Perfil', style: textTheme.titleMedium),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _nameController..addListener(() => setState(() {})),
                                decoration: InputDecoration(
                                  hintText: 'Tu nombre',
                                  filled: true,
                                  fillColor: colors.surfaceVariant.withOpacity(0.6), 
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                    borderSide: BorderSide(color: colors.primaryContainer),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                    borderSide: BorderSide(color: colors.primary, width: 2),
                                  ),
                                  suffixIcon: Icon(Icons.edit, color: colors.secondary.withOpacity(0.8)),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: (isSaving || !_hasChanges) ? null : () async {
                                  final success = await ref.read(profileControllerProvider.notifier).updateProfile(
                                    newName: _nameController.text,
                                    newAvatar: _currentAvatar,
                                  );
                                  if (mounted && success) {
                                    context.go('/profile');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: isSaving
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Guardar Cambios'),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _handleBackNavigation,
                                style: ElevatedButton.styleFrom(
  backgroundColor: colors.primaryContainer,
  foregroundColor: colors.onPrimaryContainer,
  padding: const EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  elevation: 2, 
),
                                child: const Text('Cancelar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}