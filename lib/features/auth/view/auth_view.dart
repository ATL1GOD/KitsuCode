import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_card.dart';

final authTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFEE7D05),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEE7D05),
    secondary: Color(0xFFFFF313),
    tertiary: Color.fromARGB(255, 180, 55, 247),
    surface: Color.fromARGB(0, 234, 241, 39),
    onSurface: Colors.white,
  ),
  fontFamily: 'Poppins',
);

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void switchToTab(int index) {
      _tabController.animateTo(index);
    }

    return Theme(
      data: authTheme,
      child: Scaffold(
        body: AuthBackground(
          child: AuthCard(
            tabController: _tabController,
            onSwitchToRegister: () => switchToTab(1),
            onSwitchToLogin: () => switchToTab(0),
          ),
        ),
      ),
    );
  }
}
