// lib/features/settings/view/change_password_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:animate_do/animate_do.dart'; // Animaciones
import 'package:kitsucode/features/profile/view/all_stats_view.dart'; // Fallback de color
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart'; // SectionHeader

// ✅ NUEVOS/ACLARADOS
import 'package:kitsucode/shared/widgets/static_settings_background.dart'; // Fondo estático compartido
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart'; // getAvatarColorById

class ChangePasswordView extends ConsumerStatefulWidget {
  const ChangePasswordView({super.key});

  @override
  ConsumerState<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends ConsumerState<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty)
      return 'La contraseña no puede estar vacía';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]')))
      return 'Debe tener al menos una mayúscula';
    if (!value.contains(RegExp(r'[a-z]')))
      return 'Debe tener al menos una minúscula';
    if (!value.contains(RegExp(r'[0-9]')))
      return 'Debe tener al menos un número';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      return 'Debe tener al menos un símbolo';
    return null;
  }

  void _submitChangePassword() async {
    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid) {
      if (_currentPasswordController.text.isEmpty) {
        showWarningSnackbar(
          context,
          'Campo Requerido',
          'Debes ingresar tu contraseña actual.',
        );
      } else if (_newPasswordController.text.isEmpty) {
        showWarningSnackbar(
          context,
          'Campo Requerido',
          'Debes ingresar una nueva contraseña.',
        );
      } else if (_validatePassword(_newPasswordController.text) != null) {
        showErrorSnackbar(
          context,
          'Contraseña Insegura',
          _validatePassword(_newPasswordController.text)!,
        );
      } else if (_confirmPasswordController.text.isEmpty) {
        showWarningSnackbar(
          context,
          'Campo Requerido',
          'Debes confirmar la nueva contraseña.',
        );
      } else if (_newPasswordController.text !=
          _confirmPasswordController.text) {
        showErrorSnackbar(
          context,
          'Error',
          'Las nuevas contraseñas no coinciden.',
        );
      } else {
        showErrorSnackbar(context, 'Error', 'Por favor revisa los campos.');
      }
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showErrorSnackbar(
        context,
        'Error',
        'Las nuevas contraseñas no coinciden.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = await ref.read(authRepositoryProvider.future);
      await authRepo.reauthenticate(_currentPasswordController.text);
      await authRepo.changePassword(_newPasswordController.text);
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Éxito',
          'Contraseña actualizada correctamente',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Error',
          'La contraseña actual es incorrecta.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final currentUserId = ref.watch(authStateProvider).value?.session?.user.id;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }
    final profileState = ref.watch(userProfileByIdProvider(currentUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          // ✅ Color dinámico desde BD (con fallback al método previo)
          final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
          final dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // ✅ USAR el fondo estático compartido (como en SupportView)
              StaticSettingsBackground(profile: profile, colors: colors),

              SafeArea(
                child: Column(
                  children: [
                    // --- CABECERA ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: colors.surface.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.outlineVariant.withAlpha(130),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Cambiar Contraseña',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // --- FORMULARIO ---
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          children: [
                            // Fox image colapsa con teclado (igual que tenías)
                            FadeInDown(
                              delay: const Duration(milliseconds: 100),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(
                                        sizeFactor: animation,
                                        axisAlignment: -1.0,
                                        child: child,
                                      ),
                                    ),
                                child: !isKeyboardVisible
                                    ? Padding(
                                        key: const ValueKey('fox-image'),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: Image.asset(
                                          'assets/images/auth/fox_login.png',
                                          height: 180,
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('fox-gone'),
                                      ),
                              ),
                            ),

                            FadeInDown(
                              delay: const Duration(milliseconds: 200),
                              child: SectionHeader(
                                title: 'Credenciales',
                                icon: Icons.lock_outline,
                                colors: colors,
                              ),
                            ),

                            // Campo 1
                            FadeInDown(
                              delay: const Duration(milliseconds: 300),
                              child: _TextFieldWrapper(
                                dynamicColor: dynamicColor,
                                child: TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: true,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña Actual',
                                    labelStyle: textTheme.bodyLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_person_outlined,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Ingresa tu contraseña actual'
                                      : null,
                                ),
                              ),
                            ),

                            // Campo 2
                            FadeInDown(
                              delay: const Duration(milliseconds: 400),
                              child: _TextFieldWrapper(
                                dynamicColor: dynamicColor,
                                child: TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva Contraseña',
                                    labelStyle: textTheme.bodyLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: _validatePassword,
                                ),
                              ),
                            ),

                            // Campo 3
                            FadeInDown(
                              delay: const Duration(milliseconds: 500),
                              child: _TextFieldWrapper(
                                dynamicColor: dynamicColor,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar Nueva Contraseña',
                                    labelStyle: textTheme.bodyLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_clock_outlined,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Confirma tu contraseña'
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Botón
                            FadeInDown(
                              delay: const Duration(milliseconds: 600),
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : FilledButton.icon(
                                      icon: const Icon(
                                        Icons.security_update_good_outlined,
                                      ),
                                      label: const Text(
                                        'Actualizar Contraseña',
                                      ),
                                      onPressed: _submitChangePassword,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        backgroundColor: dynamicColor,
                                        foregroundColor: colors.onPrimary,
                                        textStyle: textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextFieldWrapper extends StatelessWidget {
  final Widget child;
  final Color dynamicColor;

  const _TextFieldWrapper({required this.child, required this.dynamicColor});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface.withAlpha(242),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dynamicColor.withAlpha(153)),
        boxShadow: [
          BoxShadow(
            color: dynamicColor.withAlpha(64),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: child,
        ),
      ),
    );
  }
}
