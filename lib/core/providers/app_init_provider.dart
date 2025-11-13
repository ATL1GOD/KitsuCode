// lib/core/providers/app_init_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';

// IMPORTANTE: Importa el NUEVO provider de bootstrap
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

final appInitProvider = AsyncNotifierProvider<AppInitNotifier, void>(() {
  return AppInitNotifier();
});

class AppInitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // --- NUEVA LÍNEA ---
    // Espera a que la inicialización esencial (Firebase, Supabase) termine
    // Usamos 'watch' para que este provider se suspenda hasta que bootstrap termine.
    await ref.watch(bootstrapProvider.future);
    // --- FIN NUEVA LÍNEA ---

    debugPrint('AppInitProvider: inicio (bootstrap completado)');
    
    // Ahora es seguro leer el authState
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
        const Duration(seconds: 5),
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