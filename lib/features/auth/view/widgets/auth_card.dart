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

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'INICIAR SESIÓN'),
                Tab(text: 'REGISTRARSE'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 380, // Altura ajustada para el nuevo layout
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
    );
  }
}
