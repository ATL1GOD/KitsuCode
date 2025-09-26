import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/auth/view/widgets/form_card.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para manejar la lógica del login
  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      ref.read(authControllerProvider.notifier).login(email, password, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el estado de carga y error desde Riverpod
    final isLoading = ref.watch(authControllerProvider);
    final authError = ref.watch(authErrorProvider);

    return Scaffold(
      // Usamos el widget de fondo
      body: LoginBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Aquí puedes agregar más elementos al fondo si lo deseas
            const Positioned(
              top: 20,
              left: 50,
              child: Image(
                image: AssetImage('assets/images/login_zorro.png'),
                width: 300,
                height: 300,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Usamos el widget de formulario, pasándole todo lo que necesita
                    LoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: isLoading,
                      errorText: authError,
                      onLoginPressed:
                          _handleLogin, // Pasamos la función de login
                    ),

                    // Enlace para recuperar contraseña
                    TextButton(
                      onPressed: () {
                        // Lógica para recuperar contraseña
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
