import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart'; // Importa el archivo renombrado

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso. Revisa tu correo.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en el registro: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _googleSignIn() async {
    try {
      await ref.read(loginStateProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
                if (value == null || value.isEmpty)
                  return 'Ingresa una contraseña';
                if (value.length < 6) return 'Mínimo 6 caracteres';
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
          const AnimatedFadeIn(delay: 500, child: OrDivider()),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 600,
            child: SocialAuthButton(
              text: 'Registrarse con Google',
              iconPath:
                  'images/auth/google_logo.png', // Asegúrate que la ruta sea correcta
              isLoading: isLoading,
              onPressed: _googleSignIn,
            ),
          ),
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
