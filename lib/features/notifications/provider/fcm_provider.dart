import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/features/notifications/service/fcm_service.dart';

/// Provider del servicio FCM
/// Depende del router para poder navegar cuando se toca una notificación
final fcmServiceProvider = Provider<FCMService>((ref) {
  final router = ref.watch(routerProvider);
  return FCMService(router);
});
