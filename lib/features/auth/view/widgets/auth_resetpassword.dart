import 'dart:ui'; // Para BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';
import 'package:kitsucode/features/auth/view/auth_view.dart'; // Importa el tema

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reutilizamos el mismo tema de la pantalla de Auth
    return Theme(
      data: authTheme,
      child: const Scaffold(
        body: AuthBackground(
          child: ForgotPasswordCard(), // Usamos un Card nuevo
        ),
      ),
    );
  }
}

// --- Card y Formulario ---

class ForgotPasswordCard extends ConsumerStatefulWidget {
  const ForgotPasswordCard({super.key});

  @override
  ConsumerState<ForgotPasswordCard> createState() => _ForgotPasswordCardState();
}

class _ForgotPasswordCardState extends ConsumerState<ForgotPasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final resetNotifier = ref.read(resetPasswordProvider.notifier);
    try {
      await resetNotifier.sendResetEmail(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo de recuperación enviado. ¡Revisa tu bandeja!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/auth');
      }
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(resetPasswordProvider);
    final isLoading = resetState.isLoading;

    // Reutilizamos el estilo exacto de tu AuthCard
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
                    'Restablecer Contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withAlpha(204)),
                  ),
                  const SizedBox(height: 24),

                  // Reutilizamos tu CustomInputField
                  CustomInputField(
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
                  const SizedBox(height: 24),

                  // Reutilizamos tu PrimaryAuthButton
                  PrimaryAuthButton(
                    isLoading: isLoading,
                    text: 'Enviar Correo',
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 16),

                  // Botón para regresar
                  SwitchFormButton(
                    text: 'Recordé mi contraseña.',
                    highlightedText: 'Iniciar Sesión',
                    onPressed: () => context.go('/auth'),
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
