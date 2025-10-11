import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';
import 'package:kitsucode/features/auth/view/widgets/login_background.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Envuelve el Scaffold con el widget Theme para aplicar nuestro tema personalizado
    return Theme(
      data: AppThemes.lightTheme,
      child: const Scaffold(
        body: ResponsiveLayout(
          mobileScaffold: LoginBackground(isMobile: true),
          desktopScaffold: LoginBackground(isMobile: false),
        ),
      ),
    );
  }
}
