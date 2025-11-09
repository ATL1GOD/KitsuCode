import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart'; // Importa el archivo renombrado

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginForm({super.key, required this.onSwitchToRegister});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final loginNotifier = ref.read(loginStateProvider.notifier);
      try {
        await loginNotifier.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
    final loginState = ref.watch(loginStateProvider);

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
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa un correo'
                  : null,
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
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa una contraseña'
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedFadeIn(
            delay: 300,
            child: PrimaryAuthButton(
              isLoading: loginState.isLoading,
              text: 'Iniciar Sesión',
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 16),
          const AnimatedFadeIn(delay: 400, child: OrDivider()),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 500,
            child: SocialAuthButton(
              text: 'Continuar con Google',
              iconPath:
                  'assets/images/auth/google_logo.png', // Asegúrate que esta ruta sea correcta
              isLoading: loginState.isLoading,
              onPressed: _googleSignIn,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 600,
            child: SwitchFormButton(
              text: '¿No tienes cuenta?',
              highlightedText: 'Regístrate',
              onPressed: widget.onSwitchToRegister,
            ),
          ),
        ],
      ),
    );
  }
}
