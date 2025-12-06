import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_controller.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:animate_do/animate_do.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

import 'package:kitsucode/shared/widgets/animated_settings_background.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _currentAvatarId;
  late int _initialAvatarId;
  late UserProfileModel _currentProfileData;
  bool _isInitialized = false;

  AnimationController? _swingController;
  bool _isPageVisible = true;
  bool _isAppActive = true;

  String _currentName = "";
  String _initialName = "";
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
      _updateAnimationState();
    });
  }

  void _updateAnimationState() {
    if (_isAppActive && _isPageVisible) {
      if (_swingController?.isAnimating == false) _swingController?.repeat();
    } else {
      if (_swingController?.isAnimating == true) _swingController?.stop();
    }
  }

  void _initializeData(UserProfileModel freshProfile) {
    if (_isInitialized) return;
    _currentAvatarId = freshProfile.idAvatarSeleccionado;
    _initialAvatarId = freshProfile.idAvatarSeleccionado;
    _initialName = freshProfile.nombrePerfil;
    _currentName = freshProfile.nombrePerfil;
    _currentProfileData = freshProfile;
    _isInitialized = true;
  }

  Future<void> _handleBackNavigation() async {
    final isNameChanged = _currentName != _initialName;
    final isAvatarChanged = _currentAvatarId != _initialAvatarId;
    final hasChanges = isNameChanged || isAvatarChanged;

    if (!hasChanges || !mounted) {
      if (mounted) context.pop();
      return;
    }
    final shouldPop =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar cambios'),
            content: const Text('¿Seguro que quieres salir sin guardar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
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

    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }
    final profileAsync = ref.watch(userProfileByIdProvider(currentUserId));
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return profileAsync.when(
      data: (profile) {
        if (!_isInitialized) {
          _initializeData(profile);
        }
        _currentProfileData = profile;

        final avatars = ref.watch(currentUserAvatarsProvider).value ?? [];

        final selectedId = _isInitialized
            ? _currentAvatarId
            : profile.idAvatarSeleccionado;

        final dynamicColor = getAvatarColorById(selectedId, avatars);

        final currentAvatarPath = getAvatarAssetPathById(selectedId, avatars);

        final isNameChanged = _currentName != _initialName;
        final isAvatarChanged = _currentAvatarId != _initialAvatarId;
        final hasChanges = (isNameChanged || isAvatarChanged) && _isNameValid;

        final maxAvatarChanges = _currentProfileData.cambiosAvatarHoy >= 2;
        final maxNameChanges =
            _currentProfileData.cambiosNombrePerfilEsteMes >= 2;

        Widget avatarImage = OptimizedImage(
          imagePath: currentAvatarPath,
          fit: BoxFit.cover,
          enableCache: true,
          width: isKeyboardVisible ? 120 : 160,
          height: isKeyboardVisible ? 120 : 160,
        );

        return VisibilityDetector(
          key: const Key('edit-profile-detector'),
          onVisibilityChanged: (visibilityInfo) {
            if (!mounted) return;
            final visible = visibilityInfo.visibleFraction > 0.1;
            if (_isPageVisible != visible) {
              setState(() {
                _isPageVisible = visible;
                _updateAnimationState();
              });
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                RepaintBoundary(
                  child: AnimatedSettingsBackground(
                    profile: profile,
                    colors: colors,
                    isKeyboardVisible: isKeyboardVisible,

                    avatarIdOverride: _currentAvatarId,
                  ),
                ),

                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _handleBackNavigation,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: colors.surface.withAlpha(
                                        (255 * 0.3).round(),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AnimatedOpacity(
                                    opacity: isKeyboardVisible ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      'Editar Perfil',
                                      textAlign: TextAlign.center,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 44),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          FadeInDown(
                            duration: const Duration(milliseconds: 450),
                            delay: const Duration(milliseconds: 80),
                            from: 30,
                            child: RepaintBoundary(
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    width: isKeyboardVisible ? 120 : 160,
                                    height: isKeyboardVisible ? 120 : 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [dynamicColor, colors.primary],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: dynamicColor.withAlpha(
                                            (255 * 0.5).round(),
                                          ),
                                          blurRadius: 25,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: ClipOval(child: avatarImage),
                                  ),
                                  if (!isKeyboardVisible && !maxAvatarChanges)
                                    Positioned(
                                      bottom: -5,
                                      right: -5,
                                      child: Swing(
                                        controller: (controller) {
                                          _swingController = controller;
                                          _updateAnimationState();
                                        },
                                        manualTrigger: true,
                                        delay: const Duration(seconds: 2),
                                        child: Material(
                                          color: colors.surface,
                                          elevation: 4,
                                          shape: const CircleBorder(),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: colors.secondary,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: colors.onSecondary,
                                                size: 18,
                                              ),
                                              onPressed: () async {
                                                final newAvatarId =
                                                    await context.push<int>(
                                                      '/edit-avatar',
                                                      extra: _currentProfileData
                                                          .idAvatarSeleccionado,
                                                    );

                                                if (newAvatarId != null &&
                                                    newAvatarId !=
                                                        _currentAvatarId) {
                                                  setState(() {
                                                    _currentAvatarId =
                                                        newAvatarId;
                                                  });
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
                          ),

                          const SizedBox(height: 40),

                          FadeInUp(
                            duration: const Duration(milliseconds: 450),
                            delay: const Duration(milliseconds: 120),
                            from: 20,
                            child: _GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Nombre de Perfil',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 10),

                                    _ProfileNameInput(
                                      initialValue: _initialName,
                                      colors: colors,
                                      onChanged: (newName, isValid) {
                                        if (_currentName != newName ||
                                            _isNameValid != isValid) {
                                          setState(() {
                                            _currentName = newName;
                                            _isNameValid = isValid;
                                          });
                                        }
                                      },
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        maxNameChanges
                                            ? "Ya no puedes cambiar tu nombre este mes."
                                            : "Te ${2 - _currentProfileData.cambiosNombrePerfilEsteMes == 1 ? 'queda' : 'quedan'} ${2 - _currentProfileData.cambiosNombrePerfilEsteMes} cambios.",
                                        style: textTheme.bodySmall?.copyWith(
                                          color: maxNameChanges
                                              ? colors.error
                                              : colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),

                                    ElevatedButton(
                                      onPressed: (isSaving || !hasChanges)
                                          ? null
                                          : () async {
                                              if (isNameChanged &&
                                                  maxNameChanges) {
                                                return;
                                              }
                                              final updated = await ref
                                                  .read(
                                                    profileControllerProvider
                                                        .notifier,
                                                  )
                                                  .updateProfile(
                                                    newName: isNameChanged
                                                        ? _currentName
                                                        : null,
                                                    newAvatarId: isAvatarChanged
                                                        ? _currentAvatarId
                                                        : null,
                                                  );

                                              if (!context.mounted) return;
                                              if (updated != null) {
                                                if (isAvatarChanged) {
                                                  final cambiosRestantes =
                                                      2 -
                                                      updated.cambiosAvatarHoy;
                                                  if (cambiosRestantes > 0) {
                                                    showSuccessSnackbar(
                                                      context,
                                                      'Avatar Actualizado',
                                                      'Te ${cambiosRestantes == 1 ? 'queda' : 'quedan'} $cambiosRestantes ${cambiosRestantes == 1 ? 'cambio' : 'cambios'} de avatar hoy.',
                                                    );
                                                  } else {
                                                    showWarningSnackbar(
                                                      context,
                                                      'Avatar Actualizado',
                                                      'Has alcanzado el límite de cambios de avatar por hoy.',
                                                    );
                                                  }
                                                }
                                                context.pop();
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: colors.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: isSaving
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Guardar Cambios'),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: _handleBackNavigation,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.primary,
                                        side: BorderSide(
                                          color: colors.primary.withAlpha(128),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancelar'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Error al cargar el perfil: $e"))),
    );
  }
}

class _ProfileNameInput extends StatefulWidget {
  final String initialValue;
  final ColorScheme colors;
  final Function(String, bool) onChanged;

  const _ProfileNameInput({
    required this.initialValue,
    required this.colors,
    required this.onChanged,
  });

  @override
  State<_ProfileNameInput> createState() => _ProfileNameInputState();
}

class _ProfileNameInputState extends State<_ProfileNameInput> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    String? error;
    if (value.trim().isEmpty) {
      error = 'El nombre no puede estar vacío';
    } else if (value.length < 3) {
      error = 'Debe tener al menos 3 caracteres';
    } else if (value.length > 20) {
      error = 'Máximo 20 caracteres';
    } else if (value.contains(' ')) {
      error = 'No puede contener espacios';
    }

    setState(() {
      _errorText = error;
    });
    widget.onChanged(value, error == null);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _validate,
      decoration: InputDecoration(
        hintText: 'Tu nombre',
        filled: true,
        fillColor: widget.colors.surfaceContainerHighest.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: widget.colors.primary, width: 2),
        ),
        errorText: _errorText,
        suffixIcon: Icon(
          Icons.person_outline,
          color: widget.colors.onSurfaceVariant.withAlpha(150),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((255 * 0.4).round()),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha((255 * 0.5).round()),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
