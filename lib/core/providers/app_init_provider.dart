// lib/core/providers/app_init_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';

/// Provider que orquesta la inicialización de servicios no esenciales.
/// Se ejecuta en segundo plano al iniciar la app.
final appInitProvider = AsyncNotifierProvider<AppInitNotifier, void>(() {
  return AppInitNotifier();
});

class AppInitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    debugPrint('AppInitProvider: inicio');
    final session = ref.read(authStateProvider).value?.session;
    try {
      await Future.wait([
        ref.read(fcmServiceProvider).initialize().catchError((e) {
          debugPrint('Error FCM: $e');
        }),
        if (session != null)
          ref.read(settingsProvider.future).catchError((e) {
            debugPrint('Error settings: $e');
          }),
      ]).timeout(
        const Duration(seconds: 5), // Evita que se quede esperando para siempre
        onTimeout: () {
          debugPrint('AppInitProvider: timeout, continuando sin esperar');
          return <void>[];
        },
      );
    } catch (e) {
      debugPrint('AppInitProvider: excepción $e');
    }
    debugPrint('AppInitProvider: fin');
  }
}
