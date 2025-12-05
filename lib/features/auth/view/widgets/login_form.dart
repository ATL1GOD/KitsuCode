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
        if (mounted) {
          showSuccessSnackbar(context, '¡Éxito!', 'Inicio de sesión exitoso.');
        }
      } catch (e) {
        setState(() => _showError = true);
        if (mounted) {
          // Detectar si el error es por correo no confirmado
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('email not confirmed') || 
              errorMessage.contains('email_not_confirmed') ||
              errorMessage.contains('not confirmed')) {
            showWarningSnackbar(
              context,
              'Correo No Verificado',
              'Por favor, confirma tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o spam.',
            );
          } else if (errorMessage.contains('invalid') && errorMessage.contains('credentials')) {
            showErrorSnackbar(
              context,
              'Error de Inicio de Sesión',
              'Correo o contraseña incorrectos. Por favor, verifica tus datos.',
            );
          } else {
            showErrorSnackbar(context, 'Error', e.toString());
          }
        }
      }
    }
  }

  void _googleSignIn() async {
    try {
      await ref.read(loginStateProvider.notifier).signInWithGoogle();
      if (mounted) {
        showSuccessSnackbar(context, '¡Éxito!', 'Inicio de sesión con Google exitoso.');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        // Detectar si el correo de Google ya está registrado con otro método
        if (errorMessage.contains('user already registered') ||
            errorMessage.contains('already registered') ||
            errorMessage.contains('already exists') ||
            errorMessage.contains('email already in use') ||
            errorMessage.contains('already been registered')) {
          showWarningSnackbar(
            context,
            'Cuenta Ya Registrada',
            'Este correo de Google ya está registrado. Por favor, inicia sesión con Google o usa tu correo y contraseña.',
          );
        } else if (errorMessage.contains('cancelled') || errorMessage.contains('canceled')) {
          // Usuario canceló el inicio de sesión con Google, no mostrar error
          return;
        } else {
          showErrorSnackbar(context, 'Error con Google', e.toString());
        }
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          AnimatedFadeIn(
            delay: 300,
            child: PrimaryAuthButton(
              isLoading: loginState.isLoading,
              text: 'Iniciar Sesión',
              onPressed: loginState.isLoading ? null : _submit,
            ),
          ),
          const SizedBox(height: 6),
          const AnimatedFadeIn(delay: 400, child: OrDivider()),
          const SizedBox(height: 6),
          AnimatedFadeIn(
            delay: 500,
            child: SocialAuthButton(
              text: 'Continuar con Google',
              iconPath: 'assets/images/auth/google_logo.webp',
              isLoading: loginState.isLoading,
              onPressed: loginState.isLoading ? null : _googleSignIn,
            ),
          ),
          const SizedBox(height: 4),
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
          AnimatedFadeIn(
            delay: 700,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              // VisualDensity compact elimina el padding extra de los botones
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero, // Elimina padding vertical
                tapTargetSize: MaterialTapTargetSize
                    .shrinkWrap, // Reduce área táctil vacía
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedFadeIn(
            delay: 800,
            child: TextButton(
              onPressed: () => context.push('/privacy-policy'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Política de Privacidad y Términos',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 11, // Un poco más pequeño para footer
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
