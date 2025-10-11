import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';
// Asumimos que quieres reutilizar el mismo fondo, si no, crea uno nuevo.
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';
import 'package:kitsucode/features/auth/view/widgets/register_form.dart';

class RegisterView extends ConsumerWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppThemes.lightTheme, // o el tema que prefieras
      child: const Scaffold(
        // Reutilizamos el fondo pero le pasamos el RegisterForm
        body: ResponsiveLayout(
          mobileScaffold: LoginBackground(
            isMobile: true,
            child: RegisterForm(),
          ),
          desktopScaffold: LoginBackground(
            isMobile: false,
            child: RegisterForm(),
          ),
        ),
      ),
    );
  }
}
