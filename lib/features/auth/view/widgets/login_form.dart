import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  // Parámetros que recibirá desde la vista principal
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onLoginPressed;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    this.errorText,
    required this.onLoginPressed,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de texto para Login
          const Text(
            "Iniciar Sesión con tu Email",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.emailController, // Usa el controlador del padre
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Campo de texto para Contraseña
          const Text("Contraseña", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          TextFormField(
            controller:
                widget.passwordController, // Usa el controlador del padre
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              errorText: widget.errorText, // Muestra el error de Riverpod aquí
            ),
          ),
          const SizedBox(height: 30),

          // Botón principal de Log in o Indicador de Carga
          SizedBox(
            width: double.infinity,
            height: 50, // Altura fija para evitar saltos de layout
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed:
                        widget.onLoginPressed, // Usa la función del padre
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF263238,
                      ), // Azul oscuro/gris
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Inicia Sesión',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
