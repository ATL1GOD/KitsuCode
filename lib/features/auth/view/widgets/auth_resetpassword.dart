import 'dart:ui'; // Para BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_bottons.dart';
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: authTheme,
      child: const Scaffold(body: AuthBackground(child: ForgotPasswordCard())),
    );
  }
}

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

      // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Correo Enviado',
          '¡Revisa tu bandeja de entrada!',
        );
        context.go('/auth');
      }
    } catch (e) {
      // --- CAMBIO AQUÍ: Usamos tu Awesome Snackbar ---
      if (mounted) {
        showErrorSnackbar(context, 'Error', e.toString());
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        // 🔥 Reducido de 10 a 5 para mejor rendimiento en dispositivos de gama media-baja
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                  PrimaryAuthButton(
                    isLoading: isLoading,
                    text: 'Enviar Correo',
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 16),
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
