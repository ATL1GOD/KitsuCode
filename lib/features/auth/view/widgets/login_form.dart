import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

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

  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrors);
    _passwordController.addListener(_clearErrors);
  }

  void _clearErrors() {
    if (_showError) {
      setState(() => _showError = false);
      ref.read(loginStateProvider.notifier).clearError();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrors);
    _passwordController.removeListener(_clearErrors);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _showError = false);

      final loginNotifier = ref.read(loginStateProvider.notifier);
      try {
        await loginNotifier.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
        if (mounted) {
          showSuccessSnackbar(context, '¡Éxito!', 'Inicio de sesión exitoso.');
        }
      } catch (e) {
        setState(() => _showError = true);
        // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
        if (mounted) {
          showErrorSnackbar(context, 'Error', e.toString());
        }
      }
    }
  }

  void _googleSignIn() async {
    try {
      await ref.read(loginStateProvider.notifier).signInWithGoogle();
    } catch (e) {
      // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
      if (mounted) {
        showErrorSnackbar(context, 'Error con Google', e.toString());
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un correo';
                }
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
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa una contraseña'
                  : null,
            ),
          ),
          if (_showError && loginState.hasError) ...[
            const SizedBox(height: 8),
            AnimatedFadeIn(
              delay: 0,
              child: Text(
                'Error de autenticación. Verifica tus credenciales.',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AnimatedFadeIn(
            delay: 300,
            child: PrimaryAuthButton(
              isLoading: loginState.isLoading,
              text: 'Iniciar Sesión',
              onPressed: loginState.isLoading ? null : _submit,
            ),
          ),
          const SizedBox(height: 16),
          const AnimatedFadeIn(delay: 400, child: OrDivider()),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 500,
            child: SocialAuthButton(
              text: 'Continuar con Google',
              iconPath: 'assets/images/auth/google_logo.png',
              isLoading: loginState.isLoading,
              onPressed: loginState.isLoading ? null : _googleSignIn,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 600,
            child: SwitchFormButton(
              text: '¿No tienes cuenta?',
              highlightedText: 'Regístrate',
              onPressed: loginState.isLoading
                  ? () {}
                  : widget.onSwitchToRegister,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedFadeIn(
            delay: 700,
            child: TextButton(
              onPressed: () {
                context.go('/forgot-password');
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedFadeIn(
            delay: 800,
            child: TextButton(
              onPressed: () {
                context.push('/privacy-policy'); // Nueva ruta
              },
              child: Text(
                'Política de Privacidad y Términos',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
