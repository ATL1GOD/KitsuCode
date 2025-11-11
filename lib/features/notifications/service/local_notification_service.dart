import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. Inicialización ---
  Future<void> init() async {
    // Usa el ícono de notificación en android/app/src/main/res/drawable/
    // Este ícono es el 'smallIcon' que aparece en la barra de notificaciones
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
    await _initTimezone();
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    // Esto asume que getLocalTimezone() devuelve un String o un objeto con 'name'
    // (por ejemplo TimezoneInfo). Extraemos el nombre de zona de forma segura.
    try {
      final dynamic tzResult = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzResult is String
          ? tzResult
          : (tzResult?.name ?? tzResult?.timeZoneId ?? tzResult.toString());
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Error al obtener la zona horaria: $e. Usando UTC por defecto.');
      // Fallback a UTC si falla
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  // --- 2. Detalles de la Notificación (Estilo Duolingo) ---
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'study_reminder_channel', // ID del canal
      'Recordatorios de Estudio', // Nombre del canal
      channelDescription: 'Canal para recordatorios de práctica diaria.',
      importance: Importance.max,
      priority: Priority.high,
      // --- ¡CORREGIDO! ---
      // 'smallIcon' ya no va aquí. Se define en la inicialización (arriba).
      
      // TODO: Define un color (ej. el primario de tu app)
      // color: Color(0xFFB86914),
      
      // TODO: Para el avatar de Duolingo (imagen grande a la derecha),
      // necesitas un 'largeIcon'.
      // largeIcon: FilePathAndroidBitmap('assets/images/login_zorro.png'), // <-- ¡DEBE SER UNA RUTA NATIVA DE ANDROID!
                                                                            // No 'assets/'. Tendrías que copiar la imagen
                                                                            // a android/app/src/main/res/drawable/
                                                                            // y usar: largeIcon: DrawableResourceAndroidBitmap('login_zorro')
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
  }

  // --- 3. Programar la Alarma ---
  Future<void> scheduleStudyReminder(TimeOfDay time) async {
    await cancelStudyReminder();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      0, // ID único
      '¡Hora de practicar!', // Título
      '¡No pierdas tu racha! Entra a KitsuCode y completa tu lección de hoy. 🦊', // Cuerpo
      scheduledDate,
      _notificationDetails(),
      
      // --- ¡CORREGIDO! (API v17) ---
      // Este es el reemplazo de 'uiLocalNotificationDateInterpretation'
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
    );
  }

  // --- 4. Cancelar la Alarma ---
  Future<void> cancelStudyReminder() async {
    await _notificationsPlugin.cancel(0);
  }
}