// lib/core/providers/app_init_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

final appInitProvider = AsyncNotifierProvider<AppInitNotifier, void>(() {
  return AppInitNotifier();
});

class AppInitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // ⭐ NO bloquear → dispara bootstrap
    ref.read(bootstrapProvider);

    debugPrint('AppInit: inicio');

    final session = ref.read(authStateProvider).value?.session;

    // ⭐ Fase 2 — no esencial
    Future.microtask(() async {
      try {
        await Future.wait([
          ref.read(fcmServiceProvider).initialize(),
          if (session != null) ref.read(settingsProvider.future),
        ]).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('AppInit Timeout');
            return <void>[]; // FIX CORRECTO
          },
        );
      } catch (e) {
        debugPrint('AppInit ERROR: $e');
      }

      debugPrint('AppInit: fin');
    });

    return;
  }
}
