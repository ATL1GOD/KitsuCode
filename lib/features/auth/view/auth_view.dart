import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_card.dart';

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

    final authCard = AuthCard(
      tabController: _tabController,
      onSwitchToRegister: () => switchToTab(1),
      onSwitchToLogin: () => switchToTab(0),
    );

    return Theme(
      data: AppThemes.lightTheme,
      child: Scaffold(
        body: ResponsiveLayout(
          mobileScaffold: AuthBackground(isMobile: true, child: authCard),
          desktopScaffold: AuthBackground(isMobile: false, child: authCard),
        ),
      ),
    );
  }
}
