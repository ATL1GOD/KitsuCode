import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

final appInitProvider = AsyncNotifierProvider<AppInitNotifier, void>(() {
  return AppInitNotifier();
});

class AppInitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    ref.read(bootstrapProvider);

    debugPrint('AppInit: inicio');

    final session = ref.read(authStateProvider).value?.session;

    Future.microtask(() async {
      try {
        await ref.read(bootstrapProvider.future);

        if (session != null) {
          await ref
              .read(settingsProvider.future)
              .timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('AppInit ERROR (no crítico): $e');
      }
      debugPrint('AppInit: fin');
    });

    return;
  }
}
