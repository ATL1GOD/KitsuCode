// lib/features/settings/view/change_password_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:animate_do/animate_do.dart'; // <--- REINSTALADO
import 'package:kitsucode/features/profile/view/all_stats_view.dart'; // Para getHeaderColor
import 'package:kitsucode/features/settings/view/widgets/settings_tiles.dart'; // Importa SectionHeader

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

  // --- VALIDACIÓN DE CONTRASEÑA (Sin cambios) ---
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe tener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe tener al menos una minúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe tener al menos un número';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe tener al menos un símbolo';
    }
    return null;
  }

  // --- LÓGICA DE SUBMIT (Sin cambios) ---
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
      // --- 1. OBTENER EL REPOSITORIO UNA VEZ ---
      final authRepo = await ref.read(authRepositoryProvider.future);

      // --- 2. USAR EL REPOSITORIO OBTENIDO ---
      await authRepo.reauthenticate(_currentPasswordController.text);

      // --- 3. USARLO DE NUEVO ---
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- FONDO (Estático) ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha(100),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),

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

                    // --- LISTVIEW (Formulario) ---
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          children: [
                            // --- IMAGEN DEL ZORRO (Con FadeInDown, y colapsando con teclado) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
                              delay: const Duration(milliseconds: 100),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SizeTransition(
                                          sizeFactor: animation,
                                          axisAlignment: -1.0,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: !isKeyboardVisible
                                    ? Padding(
                                        key: const ValueKey('fox-image'),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: Image.asset(
                                          'assets/images/auth/fox_login.webp',
                                          height: 180,
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('fox-gone'),
                                      ),
                              ),
                            ),

                            // --- Sección de Credenciales (Con FadeInDown) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
                              delay: const Duration(milliseconds: 200),
                              child: SectionHeader(
                                title: 'Credenciales',
                                icon: Icons.lock_outline,
                                colors: colors,
                              ),
                            ),

                            // --- CAMPO 1 (Con FadeInDown) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
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
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'Ingresa tu contraseña actual'
                                      : null,
                                ),
                              ),
                            ),

                            // --- CAMPO 2 (Con FadeInDown) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
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

                            // --- CAMPO 3 (Con FadeInDown) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
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
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'Confirma tu contraseña'
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // --- BOTÓN (Con FadeInDown) ---
                            FadeInDown(
                              // <--- ANIMACIÓN REINSTALADA
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

// --- WRAPPER (Sin cambios) ---
class _TextFieldWrapper extends StatelessWidget {
  final Widget child;
  final Color dynamicColor;

  const _TextFieldWrapper({required this.child, required this.dynamicColor});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Decoración idéntica a _BaseSettingsTile (o _StatsCard en apariencia)
      decoration: BoxDecoration(
        color: c.surface.withAlpha(242), // .withOpacity(.95)
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dynamicColor.withAlpha(153),
        ), // .withOpacity(.6)
        boxShadow: [
          BoxShadow(
            color: dynamicColor.withAlpha(64), // .withOpacity(.25)
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
