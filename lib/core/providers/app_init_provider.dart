// lib/core/providers/app_init_provider.dart

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
    // 1. Disparar bootstrap sin esperar (fire-and-forget inicial)
    ref.read(bootstrapProvider);

    debugPrint('AppInit: inicio');

    final session = ref.read(authStateProvider).value?.session;

    // 2. Tarea secundaria: Cargar preferencias en segundo plano
    Future.microtask(() async {
      try {
        // Esperamos a que la infraestructura (Firebase/Supabase) esté lista
        await ref.read(bootstrapProvider.future);

        // Cargamos settings visuales si hay usuario
        if (session != null) {
          // 🔥 CORRECCIÓN: Quitamos el onTimeout manual. 
          // Si tarda más de 5s, lanzará excepción y el catch la atrapará.
          await ref.read(settingsProvider.future).timeout(
            const Duration(seconds: 5),
          );
        }
      } catch (e) {
        // Aquí caerá el TimeoutException si ocurre, sin romper la app
        debugPrint('AppInit ERROR (no crítico): $e');
      }
      debugPrint('AppInit: fin');
    });

    return;
  }
}