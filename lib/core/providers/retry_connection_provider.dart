// lib/core/providers/retry_connection_provider.dart

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/connectivity_provider.dart';

/// Provider que maneja la lógica de reintentar conexión y redirigir correctamente
final retryConnectionProvider = Provider<Future<String> Function()>((ref) {
  return () async {
    if (kDebugMode) debugPrint('🔄 Reintentando conexión...');

    // Marcar que estamos recuperando
    ref.read(isRecoveringFromOfflineProvider.notifier).state = true;

    try {
      // 1. Invalidar bootstrap para reiniciar servicios
      ref.invalidate(bootstrapProvider);

      // 2. Esperar a que bootstrap termine
      // (Si esto falla, el catch de abajo lo atrapará)
      await ref.read(bootstrapProvider.future);

      // 3. 🔥 ¡NUEVO PASO CRUCIAL!
      // Invalidar y re-ejecutar la verificación de conectividad inicial.
      ref.invalidate(initialConnectivityProvider);
      final status = await ref.read(initialConnectivityProvider.future);

      // 4. 🔥 SI SIGUE OFFLINE, lanzar un error.
      // Esto será atrapado por el 'catch' en NoInternetView._handleRetry
      if (status == ConnectivityStatus.offline) {
        if (kDebugMode) debugPrint('❌ Verificación fallida. Sigue offline.');
        throw Exception('Sigue sin conexión');
      }

      // 5. SI LLEGAMOS AQUÍ, SÍ HAY INTERNET.
      // Ahora sí, refrescamos la sesión.
      ref.invalidate(authStateProvider);

      // 6. Pequeño delay para estabilizar
      await Future.delayed(const Duration(milliseconds: 500));

      // 7. Verificar estado de autenticación
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull?.session != null;

      if (kDebugMode) debugPrint('✅ Reconexión exitosa');

      // 8. Devolver ruta de destino según autenticación
      return isAuthenticated ? '/home' : '/auth';

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error al reconectar: $e');
      rethrow; // Re-lanzar para que NoInternetView._handleRetry lo atrape
    } finally {
      ref.read(isRecoveringFromOfflineProvider.notifier).state = false;
    }
  };
});