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
// 🔥 1. IMPORTAR
import 'package:visibility_detector/visibility_detector.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

// --- 🔥 2. AÑADIR WidgetsBindingObserver ---
class _EditProfileViewState extends ConsumerState<EditProfileView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TextEditingController? _nameController;
  String? _nameValidationError;
  late int _currentAvatarId;
  late int _initialAvatarId;
  late String _initialName;
  late UserProfileModel _currentProfileData;
  bool _isInitialized = false;

  // --- 🔥 3. CONTROLADORES Y ESTADO DE ANIMACIÓN ---
  late final AnimationController _lottieController;
  AnimationController? _swingController; // Controlador para AnimateDo
  bool _isPageVisible = true;
  bool _isAppActive = true;
  bool _isLottieLoaded = false;

  // --- 🔥 4. MODIFICAR initState Y dispose ---
  @override
  void initState() {
    super.initState();
    // Inicializar sin duración, onLoaded la asignará
    _lottieController = AnimationController(vsync: this);
    // Registrar el observador de ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController?.dispose();
    }
    _lottieController.dispose();
    // _swingController es manejado por AnimateDo, no necesita dispose aquí
    WidgetsBinding.instance.removeObserver(this); // Limpiar observador
    super.dispose();
  }

  // --- 🔥 5. AÑADIR CONTROLADORES DE CICLO DE VIDA ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
      _updateAnimationState();
    });
  }

  // Lógica central para controlar AMBAS animaciones
  void _updateAnimationState() {
    // Lógica para Lottie
    if (_isAppActive && _isPageVisible && _isLottieLoaded) {
      _lottieController.repeat();
    } else {
      _lottieController.stop();
    }

    // Lógica para el botón 'Swing' de AnimateDo
    if (_isAppActive && _isPageVisible) {
      _swingController?.repeat(); // Iniciar si existe
    } else {
      _swingController?.stop(); // Detener si existe
    }
  }

  // --- (Tus métodos _initializeControllers, _validateProfileName, _handleBackNavigation
  //      se quedan exactamente igual) ---
  void _initializeControllers(UserProfileModel freshProfile) {
    if (_isInitialized) return;
    _nameController = TextEditingController(text: freshProfile.nombrePerfil);
    _currentAvatarId = freshProfile.idAvatarSeleccionado;
    _initialAvatarId = freshProfile.idAvatarSeleccionado;
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

  Future<void> _handleBackNavigation(bool hasChanges) async {
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
    // ... (Tu lógica de providers y variables se queda igual) ...
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
        // ... (Tu lógica de 'data' se queda igual) ...
        if (!_isInitialized) {
          _initializeControllers(profile);
          Future.delayed(const Duration(milliseconds: 80), () {
            if (mounted) setState(() {});
          });
        }
        _currentProfileData = profile;

        // ⬇️⬇️⬇️ CORRECCIÓN: usar la lista de avatares para obtener el color real de BD
        final avatars = ref.watch(currentUserAvatarsProvider).value ?? [];
        final selectedIdForColor = _isInitialized
            ? _currentAvatarId
            : profile.idAvatarSeleccionado;
        final dynamicColor = getAvatarColorById(selectedIdForColor, avatars);
        // ⬆️⬆️⬆️ FIN DE LA CORRECCIÓN

        final remainingName =
            2 - _currentProfileData.cambiosNombrePerfilEsteMes;
        final nameVerb = remainingName == 1 ? 'queda' : 'quedan';
        final nameNoun = remainingName == 1 ? 'cambio' : 'cambios';
        final nameMessage =
            'Te $nameVerb $remainingName $nameNoun de nombre este mes.';

        final isNameChanged =
            _isInitialized && _nameController!.text != _initialName;
        final isAvatarChanged =
            _isInitialized && _currentAvatarId != _initialAvatarId;

        final hasChanges = isNameChanged || isAvatarChanged;
        final maxAvatarChanges = _currentProfileData.cambiosAvatarHoy >= 2;
        final maxNameChanges =
            _currentProfileData.cambiosNombrePerfilEsteMes >= 2;

        final currentAvatarPath = getAvatarAssetPathById(
          _isInitialized ? _currentAvatarId : profile.idAvatarSeleccionado,
          avatars,
        );
        Widget avatarImage = _isInitialized
            ? OptimizedImage(
                imagePath: currentAvatarPath,
                fit: BoxFit.cover,
                enableCache: true,
                width: isKeyboardVisible ? 120 : 160, // requerido
                height: isKeyboardVisible ? 120 : 160, // requerido
              )
            : const SizedBox.shrink();

        // --- 🔥 6. ENVOLVER EL SCAFFOLD CON VISIBILITYDETECTOR ---
        return VisibilityDetector(
          key: const Key('edit-profile-detector'),
          onVisibilityChanged: (visibilityInfo) {
            if (!mounted) return;
            setState(() {
              _isPageVisible = visibilityInfo.visibleFraction > 0.1;
              _updateAnimationState();
            });
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // ... (Tu AnimatedContainer de fondo no cambia) ...
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
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),

                // --- ANIMACIÓN DE FONDO OPTIMIZADA ---
                // 🔥 RepaintBoundary para aislar la animación
                AnimatedOpacity(
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: RepaintBoundary(
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.white.withAlpha(0)],
                          stops: const [0.6, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 350,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                colors.secondaryFixedDim.withAlpha(128),
                                BlendMode.srcIn,
                              ),
                              child: Lottie.asset(
                                'assets/animations/spring.json',
                                fit: BoxFit.cover,
                                // 🔥 Reducir framerate a 30 para mejor rendimiento
                                frameRate: FrameRate(30),
                                controller: _lottieController,
                                onLoaded: (composition) {
                                  if (!mounted) return;
                                  if (_lottieController.duration !=
                                      composition.duration) {
                                    _lottieController.duration =
                                        composition.duration;
                                  }
                                  _isLottieLoaded = true;
                                  _updateAnimationState();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- CONTENIDO PRINCIPAL ---
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ... (Tu barra superior no cambia) ...
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => _handleBackNavigation(hasChanges),
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
                                  duration: const Duration(milliseconds: 250),
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
                          // 🔥 RepaintBoundary para aislar el avatar animado
                          child: RepaintBoundary(
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
                                  gradient: LinearGradient(
                                    colors: [dynamicColor, colors.primary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dynamicColor.withAlpha(
                                        (255 * 0.7).round(),
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
                                  // --- 🔥 8. CONTROLAR EL SWING ---
                                  child: Swing(
                                    // Pasa un controlador al Swing
                                    controller: (controller) {
                                      _swingController = controller;
                                      _updateAnimationState(); // Sincronizar estado
                                    },
                                    manualTrigger:
                                        true, // Lo controlamos nosotros
                                    // infinite: true, // 'repeat' lo hace infinito
                                    delay: const Duration(seconds: 2),
                                    child: Material(
                                      // ... (el resto del botón no cambia) ...
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
                                            if (maxAvatarChanges) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Ya no puedes cambiar tu avatar hoy (máx 2 veces).',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                            final newAvatarId = await context
                                                .push<int>(
                                                  '/edit-avatar',
                                                  extra: _currentProfileData
                                                      .idAvatarSeleccionado,
                                                );

                                            if (newAvatarId != null &&
                                                newAvatarId !=
                                                    _currentAvatarId) {
                                              setState(() {
                                                _currentAvatarId = newAvatarId;
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Nombre de Perfil',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_isInitialized)
                                    TextField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: 'Tu nombre',
                                        filled: true,
                                        fillColor: colors
                                            .surfaceContainerHighest
                                            .withAlpha((255 * 0.5).round()),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorText: _nameValidationError,
                                        suffixIcon: Icon(
                                          Icons.person_outline,
                                          color: colors.onSurfaceVariant
                                              .withAlpha((255 * 0.6).round()),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      maxNameChanges
                                          ? "Ya no puedes cambiar tu nombre este mes."
                                          : nameMessage,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: maxNameChanges
                                            ? colors.error
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed:
                                        (isSaving ||
                                            !hasChanges ||
                                            (_nameValidationError != null &&
                                                isNameChanged))
                                        ? null
                                        : () async {
                                            if (isNameChanged &&
                                                maxNameChanges) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Ya no puedes cambiar tu nombre este mes.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            final updatedProfile = await ref
                                                .read(
                                                  profileControllerProvider
                                                      .notifier,
                                                )
                                                .updateProfile(
                                                  newName: isNameChanged
                                                      ? _nameController!.text
                                                      : null,
                                                  newAvatarId: isAvatarChanged
                                                      ? _currentAvatarId
                                                      : null,
                                                );

                                            if (!context.mounted) return;
                                            if (updatedProfile != null) {
                                              if (isAvatarChanged) {
                                                final remainingAvatar =
                                                    2 -
                                                    updatedProfile
                                                        .cambiosAvatarHoy;
                                                final avatarSnackBarMessage =
                                                    remainingAvatar > 0
                                                    ? 'Te queda 1 cambio de avatar hoy.'
                                                    : 'Límite de cambios de avatar alcanzado hoy.';
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      avatarSnackBarMessage,
                                                    ),
                                                  ),
                                                );
                                              }
                                              context.pop();
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Error al guardar cambios',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                    onPressed: () =>
                                        _handleBackNavigation(hasChanges),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.primary,
                                      side: BorderSide(
                                        color: colors.primary.withAlpha(128),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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

// 🔥 OPTIMIZADO: _GlassCard sin BackdropFilter costoso
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        decoration: BoxDecoration(
          // 🔥 Efecto de vidrio simulado sin BackdropFilter
          color: colors.surface.withAlpha((255 * 0.85).round()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha((255 * 0.3).round()),
            width: 1.5,
          ),
          // Sombra suave para dar profundidad
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
