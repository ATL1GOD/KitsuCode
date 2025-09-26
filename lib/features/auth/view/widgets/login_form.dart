import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';

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

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginStateProvider);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomInputField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.person,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa un correo'
                  : null,
            ),
            const SizedBox(height: 16),
            CustomInputField(
              controller: _passwordController,
              hintText: 'Contraseña',
              prefixIcon: Icons.lock,
              isPassword: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa una contraseña'
                  : null,
            ),
            const SizedBox(height: 24),
            PrimaryAuthButton(
              isLoading: loginState.isLoading,
              text: 'Iniciar Sesión',
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            SwitchFormButton(
              text: '¿No tienes cuenta? Registrarse',
              onPressed: widget.onSwitchToRegister,
            ),
          ],
        ),
      ),
    );
  }
}
