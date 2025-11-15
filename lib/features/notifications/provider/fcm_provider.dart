import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/features/notifications/service/fcm_service.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Provider del servicio FCM
/// (Este es tu provider. Está perfecto)
/// Depende del router para poder navegar cuando se toca una notificación
final fcmServiceProvider = Provider<FCMService>((ref) {
  final router = ref.watch(routerProvider);
  return FCMService(router, ref);
});


// --- 👇 ¡AQUÍ ESTÁ LA ADICIÓN! 👇 ---
// Añade este provider en el mismo archivo.

/// Este provider "activa" el servicio FCM cuando el usuario inicia sesión.
/// Es de "disparar y olvidar" y se observa (watch) en MyApp.
final fcmInitializationProvider = Provider<void>((ref) {
  
  // Escucha los cambios en el estado de autenticación
  ref.listen(authStateProvider, (previous, next) {

    // Reacciona solo cuando el estado tenga datos
    next.whenData((authState) {
      if (authState.session != null) {
        // ✅ Usuario autenticado
        if (kDebugMode) debugPrint("FCM: Usuario autenticado. Inicializando FCM Service...");
        try {
          // Obtenemos el servicio (del provider de arriba) y lo inicializamos.
          // NO usamos 'await' para no bloquear.
          ref.read(fcmServiceProvider).initialize();
        } catch (e) {
          if (kDebugMode) debugPrint('Error al inicializar FCM Service: $e');
        }
      } else {
        // ❔ Usuario cerró sesión
        if (kDebugMode) debugPrint("FCM: Usuario cerró sesión. Eliminando token.");
        // Llamamos a deleteToken() para limpiar el token de la BD
        ref.read(fcmServiceProvider).deleteToken();
      }
    });
  });
});