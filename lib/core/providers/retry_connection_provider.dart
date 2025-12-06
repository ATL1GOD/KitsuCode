import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/connectivity_provider.dart';

final retryConnectionProvider = Provider<Future<String> Function()>((ref) {
  return () async {
    debugPrint('🔄 Reintentando conexión...');

    ref.read(isRecoveringFromOfflineProvider.notifier).state = true;

    try {
      ref.invalidate(bootstrapProvider);

      await ref.read(bootstrapProvider.future);

      ref.invalidate(initialConnectivityProvider);
      final status = await ref.read(initialConnectivityProvider.future);

      if (status == ConnectivityStatus.offline) {
        debugPrint('❌ Verificación fallida. Sigue offline.');
        throw Exception('Sigue sin conexión');
      }

      ref.invalidate(authStateProvider);

      await Future.delayed(const Duration(milliseconds: 500));

      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull?.session != null;

      debugPrint('✅ Reconexión exitosa');

      return isAuthenticated ? '/home' : '/auth';
    } catch (e) {
      debugPrint('❌ Error al reconectar: $e');
      rethrow;
    } finally {
      ref.read(isRecoveringFromOfflineProvider.notifier).state = false;
    }
  };
});
