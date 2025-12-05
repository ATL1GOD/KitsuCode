import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

class RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterForm({super.key, required this.onSwitchToLogin});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final registerNotifier = ref.read(registerStateProvider.notifier);
      try {
        await registerNotifier.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (mounted) {
          // Limpiar los campos del formulario
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          
          // Mostrar snackbar de éxito
          showSuccessSnackbar(
            context,
            '¡Registro Exitoso!',
            'Te hemos enviado un enlace de confirmación a tu correo. Por favor, verifica tu correo antes de iniciar sesión.',
          );
          
          // Cambiar al tab de login
          widget.onSwitchToLogin();
        }
      } catch (e) {
        if (mounted) {
          // Detectar si el correo ya está registrado
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('user already registered') ||
              errorMessage.contains('already registered') ||
              errorMessage.contains('already exists') ||
              errorMessage.contains('email already in use') ||
              errorMessage.contains('already been registered')) {
            // Limpiar los campos
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            
            showWarningSnackbar(
              context,
              'Correo Ya Registrado',
              'Este correo ya está registrado. Por favor, inicia sesión con tu cuenta existente.',
            );
            
            // Cambiar al tab de login
            widget.onSwitchToLogin();
          } else {
            showErrorSnackbar(context, 'Error en el Registro', e.toString());
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerStateProvider);
    final loginState = ref.watch(loginStateProvider);
    final isLoading = registerState.isLoading || loginState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedFadeIn(
            delay: 100,
            child: CustomInputField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa un correo';
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 200,
            child: CustomInputField(
              controller: _passwordController,
              hintText: 'Contraseña',
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
                final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
                final hasDigits = RegExp(r'[0-9]').hasMatch(value);
                final hasSpecialChars = RegExp(
                  r'[!@#$%^&*(),.?":{}|<>]',
                ).hasMatch(value);

                if (!hasUppercase) return 'Incluye al menos una mayúscula';
                if (!hasLowercase) return 'Incluye al menos una minúscula';
                if (!hasDigits) return 'Incluye al menos un número';
                if (!hasSpecialChars) return 'Incluye al menos un símbolo';

                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 300,
            child: CustomInputField(
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
          ),
          const SizedBox(height: 24),
          AnimatedFadeIn(
            delay: 400,
            child: PrimaryAuthButton(
              isLoading: isLoading,
              text: 'Crear Cuenta',
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 700,
            child: SwitchFormButton(
              text: '¿Ya tienes una cuenta?',
              highlightedText: 'Inicia Sesión',
              onPressed: widget.onSwitchToLogin,
            ),
          ),
        ],
      ),
    );
  }
}
