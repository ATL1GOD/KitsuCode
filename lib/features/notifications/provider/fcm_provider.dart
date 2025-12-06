import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/features/notifications/service/fcm_service.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  final router = ref.watch(routerProvider);
  return FCMService(router, ref);
});

final fcmInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(bootstrapProvider.future);

  debugPrint(
    "🔔 FCM Provider: Infraestructura lista. Iniciando vigilancia de sesión...",
  );

  void handleAuthState(AsyncValue<AuthState> authState) {
    authState.whenData((state) {
      if (state.session != null) {
        try {
          ref.read(fcmServiceProvider).initialize();
        } catch (e) {
          debugPrint('❌ FCM Error al inicializar: $e');
        }
      } else {
        debugPrint("🔕 FCM: Sin usuario. Limpiando token...");
        try {
          ref.read(fcmServiceProvider).deleteToken();
        } catch (e) {
          debugPrint('❌ FCM Error al borrar token: $e');
        }
      }
    });
  }

  ref.listen(authStateProvider, (previous, next) {
    handleAuthState(next);
  });

  final currentAuth = ref.read(authStateProvider);
  handleAuthState(currentAuth);
});
