// lib/features/notifications/provider/fcm_provider.dart

import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/features/notifications/service/fcm_service.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';
// 🔥 CORRECCIÓN: Importar Supabase para que 'AuthState' sea reconocido
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider del servicio (Clase lógica)
final fcmServiceProvider = Provider<FCMService>((ref) {
  final router = ref.watch(routerProvider);
  return FCMService(router, ref);
});

// --- Provider inteligente de inicialización ---
final fcmInitializationProvider = FutureProvider<void>((ref) async {
  
  // 1. Esperar a que Firebase esté listo (evita crash [core/no-app])
  await ref.watch(bootstrapProvider.future);
  
  debugPrint("🔔 FCM Provider: Infraestructura lista. Iniciando vigilancia de sesión...");

  // 2. Definimos qué hacer cuando cambia el estado del usuario
  void handleAuthState(AsyncValue<AuthState> authState) {
    authState.whenData((state) {
      // Ahora 'state' es de tipo AuthState, así que 'state.session' es seguro
      if (state.session != null) {
        // ✅ HAY USUARIO
        try {
          ref.read(fcmServiceProvider).initialize();
        } catch (e) {
          debugPrint('❌ FCM Error al inicializar: $e');
        }
      } else {
        // 🚪 NO HAY USUARIO
        debugPrint("🔕 FCM: Sin usuario. Limpiando token...");
        try {
          ref.read(fcmServiceProvider).deleteToken();
        } catch (e) {
          debugPrint('❌ FCM Error al borrar token: $e');
        }
      }
    });
  }

  // 3. Escuchar cambios en vivo
  ref.listen(authStateProvider, (previous, next) {
    handleAuthState(next);
  });

  // 4. Ejecutar al inicio
  final currentAuth = ref.read(authStateProvider);
  handleAuthState(currentAuth);
});