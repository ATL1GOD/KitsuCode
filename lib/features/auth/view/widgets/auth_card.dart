import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kitsucode/features/auth/view/widgets/login_form.dart';
import 'package:kitsucode/features/auth/view/widgets/register_form.dart';

class AuthCard extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onSwitchToRegister;
  final VoidCallback onSwitchToLogin;

  const AuthCard({
    super.key,
    required this.tabController,
    required this.onSwitchToRegister,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(51),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    dividerHeight: 0,
                    controller: tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.primary,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'INICIAR SESIÓN'),
                      Tab(text: 'REGISTRARSE'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 450, // <--
                  // La altura se ajustará por el contenido
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      LoginForm(onSwitchToRegister: onSwitchToRegister),
                      RegisterForm(onSwitchToLogin: onSwitchToLogin),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
