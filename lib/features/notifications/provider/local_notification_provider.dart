import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/notifications/service/local_notification_service.dart';

final localNotificationProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
