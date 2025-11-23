import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

class UpdatePasswordView extends StatelessWidget {
  const UpdatePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: authTheme,
      child: const Scaffold(body: AuthBackground(child: UpdatePasswordCard())),
    );
  }
}

class UpdatePasswordCard extends ConsumerStatefulWidget {
  const UpdatePasswordCard({super.key});

  @override
  ConsumerState<UpdatePasswordCard> createState() => _UpdatePasswordCardState();
}

class _UpdatePasswordCardState extends ConsumerState<UpdatePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(updatePasswordProvider.notifier)
          .updatePassword(_passwordController.text);

      // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
      if (mounted) {
        showSuccessSnackbar(
          context,
          '¡Éxito!',
          'Contraseña actualizada con éxito.',
        );
        context.go('/home'); // ¡Éxito! Lo mandamos al Home.
      }
    } catch (e) {
      // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
      if (mounted) {
        showErrorSnackbar(context, 'Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updatePasswordProvider);
    final isLoading = updateState.isLoading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(100),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(51)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear Nueva Contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa tu nueva contraseña segura.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withAlpha(204)),
                  ),
                  const SizedBox(height: 24),
                  CustomInputField(
                    controller: _passwordController,
                    hintText: 'Nueva Contraseña',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                      final hasDigits = RegExp(r'[0-9]').hasMatch(value);
                      final hasSpecialChars = RegExp(
                        r'[!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value);
                      if (!hasUppercase) {
                        return 'Incluye al menos una mayúscula';
                      }
                      if (!hasDigits) return 'Incluye al menos un número';
                      if (!hasSpecialChars) {
                        return 'Incluye al menos un símbolo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirmar Contraseña',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryAuthButton(
                    isLoading: isLoading,
                    text: 'Guardar Contraseña',
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
