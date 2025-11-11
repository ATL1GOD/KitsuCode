import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio simplificado de notificaciones locales
/// Solo maneja la inicialización básica del canal de notificaciones.
/// Las notificaciones push se manejan a través de FCM y Edge Functions.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicialización básica del servicio de notificaciones
  Future<void> init() async {
    debugPrint(' [NOTIFICACIÓN] Inicializando servicio de notificaciones...');
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(settings);
    
    // Crear canal de notificaciones
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'study_reminder_channel',
      'Recordatorios de Estudio',
      description: 'Canal para recordatorios de práctica diaria.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    debugPrint(' [NOTIFICACIÓN] Canal de notificaciones creado: study_reminder_channel');
    debugPrint(' [NOTIFICACIÓN] Servicio inicializado correctamente');
  }
}