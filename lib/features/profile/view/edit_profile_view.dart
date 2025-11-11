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
import 'package:lottie/lottie.dart'; 

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  
  TextEditingController? _nameController;
  String? _nameValidationError;

  late int _currentAvatarId;
  late int _initialAvatarId; // ✅ Guardamos el avatar inicial
  late String _initialName;
  late UserProfileModel _currentProfileData;

  bool _isInitialized = false;

  static Color getHeaderColor(UserProfileModel userProfile, ColorScheme colors) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  void _initializeControllers(UserProfileModel freshProfile) {
    if (_isInitialized) return;

    _nameController = TextEditingController(text: freshProfile.nombrePerfil);
    _currentAvatarId = freshProfile.idAvatarSeleccionado;
    _initialAvatarId = freshProfile.idAvatarSeleccionado; // ✅ Guardamos el inicial
    _initialName = freshProfile.nombrePerfil;
    _currentProfileData = freshProfile;

    _validateProfileName(_nameController!.text);

    _nameController!.addListener(() {
      setState(() {
        _validateProfileName(_nameController!.text);
      });
    });
    _isInitialized = true;
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
    if (_isInitialized) {
      _nameController?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleBackNavigation(bool hasChanges) async {
    if (!hasChanges || !mounted) {
      if (mounted) context.pop();
      return;
    }

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
  _initializeControllers(profile);

  Future.delayed(const Duration(milliseconds: 80), () {
    if (mounted) setState(() {});
  });
}
        _currentProfileData = profile;
        
        final tempProfileForColor = profile.copyWith(idAvatarSeleccionado: _isInitialized ? _currentAvatarId : profile.idAvatarSeleccionado);
        final dynamicColor = getHeaderColor(tempProfileForColor, colors);

        final remainingName = 2 - _currentProfileData.cambiosNombrePerfilEsteMes;
        final nameVerb = remainingName == 1 ? 'queda' : 'quedan';
        final nameNoun = remainingName == 1 ? 'cambio' : 'cambios';
        final nameMessage = 'Te $nameVerb $remainingName $nameNoun de nombre este mes.';
        
        final isNameChanged = _isInitialized && _nameController!.text != _initialName;
        
        // ✅ CORREGIDO: Comparamos con el avatar INICIAL, no con el del stream
        final isAvatarChanged = _isInitialized && _currentAvatarId != _initialAvatarId;
        
        final hasChanges = isNameChanged || isAvatarChanged;

        final maxAvatarChanges = _currentProfileData.cambiosAvatarHoy >= 2;
        final maxNameChanges = _currentProfileData.cambiosNombrePerfilEsteMes >= 2;
        
        final currentAvatarPath = getAvatarAssetPathById(_isInitialized ? _currentAvatarId : profile.idAvatarSeleccionado);
        Widget avatarImage = _isInitialized 
          ? Image.asset(currentAvatarPath, fit: BoxFit.cover)
          : const SizedBox.shrink();

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha((255 * 0.4).round()),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.6]
                  ),
                ),
              ),

              // --- ANIMACIÓN DE FONDO ---
              AnimatedOpacity(
                opacity: isKeyboardVisible ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: ShaderMask(
  shaderCallback: (rect) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white.withOpacity(0.0)],
      stops: const [0.6, 1.0],
    ).createShader(rect);
  },
  blendMode: BlendMode.dstIn,
  child: Stack( // ✅ ahora sí puede haber Positioned
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 350,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            colors.secondaryFixedDim.withOpacity(0.5),
            BlendMode.srcIn,
          ),
          child: Lottie.asset(
            'assets/animations/spring.json',
            fit: BoxFit.cover,
            frameRate: FrameRate(40),
          ),
        ),
      ),
    ],
  ),
),              
),
              // --- CONTENIDO PRINCIPAL ---
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _handleBackNavigation(hasChanges),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: colors.surface.withAlpha((255 * 0.3).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: isKeyboardVisible ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  'Editar Perfil',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeInDown(
  duration: Duration(milliseconds: 450),
  delay: Duration(milliseconds: 80),
  from: 30,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: isKeyboardVisible ? 120 : 160,
                              height: isKeyboardVisible ? 120 : 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [dynamicColor, colors.primary]),
                                boxShadow: [
                                  BoxShadow(
                                    color: dynamicColor.withAlpha((255 * 0.7).round()),
                                    blurRadius: 25,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: avatarImage,
                              ),
                            ),
                            if (!isKeyboardVisible && !maxAvatarChanges)
                              Positioned(
                                bottom: -5,
                                right: -5,
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
                                        icon: Icon(Icons.edit, color: colors.onSecondary, size: 18),
                                        onPressed: () async {
                                          if (maxAvatarChanges) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                              content: Text('Ya no puedes cambiar tu avatar hoy (máx 2 veces).'),
                                              backgroundColor: Colors.red,
                                            ));
                                            return;
                                          }
                                          final newAvatarId = await context.push<int>('/edit-avatar', extra: _currentProfileData.idAvatarSeleccionado); 
                                          
                                          if (newAvatarId != null && newAvatarId != _currentAvatarId) {
                                            setState(() { _currentAvatarId = newAvatarId; });
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
                      FadeInUp(
  duration: Duration(milliseconds: 450),
  delay: Duration(milliseconds: 120),
  from: 20,
                        child: _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Nombre de Perfil', style: textTheme.titleMedium),
                                const SizedBox(height: 10),
                                if (_isInitialized)
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Tu nombre',
                                    filled: true,
                                    fillColor: colors.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: colors.primary, width: 2),
                                    ),
                                    errorText: _nameValidationError,
                                    suffixIcon: Icon(Icons.person_outline, color: colors.onSurfaceVariant.withAlpha((255 * 0.6).round())),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    maxNameChanges ? "Ya no puedes cambiar tu nombre este mes." : nameMessage, 
                                    style: textTheme.bodySmall?.copyWith(color: maxNameChanges ? colors.error : colors.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: (isSaving || !hasChanges || (_nameValidationError != null && isNameChanged))
                                      ? null
                                      : () async {
                                        if (isNameChanged && maxNameChanges) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text('Ya no puedes cambiar tu nombre este mes.'),
                                            backgroundColor: Colors.red,
                                          ));
                                          return; 
                                        }
                                        
                                        final updatedProfile = await ref.read(profileControllerProvider.notifier).updateProfile(
                                          newName: isNameChanged ? _nameController!.text : null,
                                          newAvatarId: isAvatarChanged ? _currentAvatarId : null, 
                                        );
                                        
                                        if (!context.mounted) return;
                                        if (updatedProfile != null) {
                                          if (isAvatarChanged) {
                                            final remainingAvatar = 2 - updatedProfile.cambiosAvatarHoy;
                                            final avatarSnackBarMessage = remainingAvatar > 0
                                              ? 'Te queda 1 cambio de avatar hoy.'
                                              : 'Límite de cambios de avatar alcanzado hoy.';
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(avatarSnackBarMessage)));
                                          }
                                          context.pop();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text('Error al guardar cambios'),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  child: isSaving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar Cambios'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => _handleBackNavigation(hasChanges),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary.withAlpha(128)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
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
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error al cargar el perfil: $e"))),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.4).round()),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha((255 * 0.5).round()))
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}