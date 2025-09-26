import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_controller.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:animate_do/animate_do.dart';

class EditProfileView extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;
  const EditProfileView({super.key, required this.userProfile});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late final TextEditingController _nameController;
  String? _nameValidationError;

  late String _currentAvatar;
  late String _initialName;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userProfile.nombrePerfil);

    _currentAvatar = widget.userProfile.avatarUrl;
    _initialName = widget.userProfile.nombrePerfil;

    _validateProfileName(_nameController.text);

    _nameController.addListener(() {
      setState(() {
        _validateProfileName(_nameController.text);
      });
    });
  }

  void _validateProfileName(String value) {
    if (value.trim().isEmpty) {
      _nameValidationError = 'El nombre no puede estar vacío';
    } else if (value.length < 3) {
      _nameValidationError = 'Debe tener al menos 3 caracteres';
    } else if (value.length > 20) {
      _nameValidationError = 'No puede tener más de 20 caracteres';
    } else if (value.contains(' ')) {
      _nameValidationError = 'No puede contener espacios';
    } else {
      _nameValidationError = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleBackNavigation(bool hasChanges) async {
    if (!hasChanges) {
      // 🔹 Si NO hay cambios, salir directo
      if (mounted) context.pop();
      return;
    }

    // 🔹 Si hay cambios, mostrar diálogo
    final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar cambios'),
            content: const Text('¿Seguro que quieres salir sin guardar?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir')),
            ],
          ),
        ) ??
        false;

    if (shouldPop && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isSaving = ref.watch(profileControllerProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text("No se pudo cargar el perfil"));
        }

        // 🔹 Determinar si hay cambios (nombre o avatar) respecto a los iniciales
        final hasChanges = _nameController.text != _initialName ||
            _currentAvatar != widget.userProfile.avatarUrl;

        final maxAvatarChanges = profile.cambiosAvatarHoy >= 2;
        final maxNameChanges = profile.cambiosNombrePerfilEsteMes >= 2;
        final remainingName = 2 - profile.cambiosNombrePerfilEsteMes;

        // Avatar dinámico
        Widget avatarImage;
        if (_currentAvatar.startsWith('http')) {
          avatarImage = Image.network(_currentAvatar, fit: BoxFit.cover);
        } else {
          avatarImage = Image.asset(_currentAvatar, fit: BoxFit.cover);
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              const LoginBackground(child: SizedBox.shrink()),

              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 HEADER
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _handleBackNavigation(hasChanges),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.surface.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back_ios_new,
                                    color: colors.onSurface),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: isKeyboardVisible ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  'Editar Perfil',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 AVATAR
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: isKeyboardVisible ? 120 : 200,
                              height: isKeyboardVisible ? 120 : 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                      color: colors.secondary.withOpacity(0.4),
                                      blurRadius: 25,
                                      spreadRadius: 1)
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40.0),
                                child: avatarImage,
                              ),
                            ),
                            if (!isKeyboardVisible && !maxAvatarChanges)
                              Positioned(
                                bottom: -10,
                                right: -10,
                                child: Swing(
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
                                        icon: Icon(Icons.edit,
                                            color: colors.onSecondary,
                                            size: 18),
                                        onPressed: () async {
                                          if (maxAvatarChanges) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Ya no puedes cambiar tu avatar hoy (máx 2 veces).'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 5),
                                            ));
                                            return;
                                          }
                                          final newAvatar =
                                              await context.push<String>(
                                                  '/edit-avatar',
                                                  extra: profile.avatarUrl);
                                          if (newAvatar != null) {
                                            final updatedProfile = await ref
                                                .read(profileControllerProvider
                                                    .notifier)
                                                .updateProfile(
                                                  newAvatar: newAvatar,
                                                  newName:
                                                      _nameController.text,
                                                );
                                            if (mounted &&
                                                updatedProfile != null) {
                                              setState(() {
                                                _currentAvatar =
                                                    updatedProfile.avatarUrl;
                                                _initialName =
                                                    updatedProfile.nombrePerfil;
                                              });
                                              // 🔹 Refrescar provider para contadores
                                              ref.refresh(userProfileProvider);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Te queda ${2 - updatedProfile.cambiosAvatarHoy} cambio(s) de avatar hoy.'),
                                                duration: const Duration(
                                                    seconds: 5),
                                              ));
                                            }
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

                      const SizedBox(height: 40),

                      // 🔹 FORMULARIO
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Card(
                            color: colors.surface.withOpacity(0.8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color:
                                      colors.primaryContainer.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Nombre de Perfil',
                                      style: textTheme.titleMedium),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: 'Tu nombre',
                                      filled: true,
                                      fillColor: colors.surfaceVariant
                                          .withOpacity(0.6),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        borderSide: BorderSide(
                                            color: colors.primaryContainer),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        borderSide: BorderSide(
                                            color: colors.primary, width: 2),
                                      ),
                                      errorText: _nameValidationError,
                                      suffixIcon: Icon(Icons.edit,
                                          color:
                                              colors.secondary.withOpacity(0.8)),
                                    ),
                                  ),

                                  // 🔹 Mensaje de cambios de nombre
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      maxNameChanges
                                          ? "Ya no puedes cambiar tu nombre este mes."
                                          : "Te quedan $remainingName cambios de nombre este mes.",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: maxNameChanges
                                              ? Colors.red
                                              : Colors.grey),
                                    ),
                                  ),

                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: (isSaving ||
                                            !hasChanges ||
                                            _nameValidationError != null ||
                                            maxNameChanges)
                                        ? null
                                        : () async {
                                            final updatedProfile = await ref
                                                .read(profileControllerProvider
                                                    .notifier)
                                                .updateProfile(
                                                  newName:
                                                      _nameController.text,
                                                  newAvatar: _currentAvatar,
                                                );
                                            if (mounted &&
                                                updatedProfile != null) {
                                              setState(() {
                                                _initialName =
                                                    updatedProfile.nombrePerfil;
                                                _currentAvatar =
                                                    updatedProfile.avatarUrl;
                                              });
                                              // 🔹 Refrescar provider para contadores
                                              ref.refresh(userProfileProvider);
                                              context.go('/profile');
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Text('Guardar Cambios'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _handleBackNavigation(hasChanges),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primaryContainer,
                                      foregroundColor:
                                          colors.onPrimaryContainer,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
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
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text("Error: $e")),
      ),
    );
  }
}
