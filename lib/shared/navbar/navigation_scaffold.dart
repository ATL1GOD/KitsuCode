import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/shared/navbar/navbar.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(achievementNotifierProvider);
    ref.watch(avatarNotifierProvider);
    return Scaffold(
      extendBody: true,

      backgroundColor: Colors.transparent,

      body: navigationShell,

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: NavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(index, ref),
        ),
      ),
    );
  }

  void _onTap(int index, WidgetRef ref) {
    ref.read(navIndexProvider.notifier).state = index;

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
