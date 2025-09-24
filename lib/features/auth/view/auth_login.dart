import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/login_form.dart';
import 'package:kitsucode/features/auth/view/widgets/register_form.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

// Usamos SingleTickerProviderStateMixin para el vsync del TabController
class _AuthViewState extends ConsumerState<AuthView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controller con 2 pestañas
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Función para cambiar de pestaña, la pasaremos a los formularios hijos
    void switchToTab(int index) {
      _tabController.animateTo(index);
    }

    return Theme(
      data: AppThemes.lightTheme,
      child: Scaffold(
        body: ResponsiveLayout(
          mobileScaffold: AuthBackground(
            isMobile: true,
            // El hijo ahora es el widget que contiene la tarjeta y las pestañas
            child: AuthCard(
              tabController: _tabController,
              onSwitchToRegister: () => switchToTab(1),
              onSwitchToLogin: () => switchToTab(0),
            ),
          ),
          desktopScaffold: AuthBackground(
            isMobile: false,
            child: AuthCard(
              tabController: _tabController,
              onSwitchToRegister: () => switchToTab(1),
              onSwitchToLogin: () => switchToTab(0),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para la tarjeta que contiene los tabs y los formularios
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
            // 1. Pestañas (TabBar)
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
              // Ajusta esta altura según el contenido de tus formularios
              height: 350,
              child: TabBarView(
                controller: tabController,
                children: [
                  // Pasamos el callback para cambiar de pestaña
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
