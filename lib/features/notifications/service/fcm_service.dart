import 'dart:developer' as developer;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/follow_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';

/// 🔥 Servicio de Firebase Cloud Messaging
/// Maneja tokens FCM y recepción de notificaciones push
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoRouter? _router;
  final Ref? _ref;

  FCMService([this._router, this._ref]);

  /// 🚀 Inicializar servicio FCM
  Future<void> initialize() async {
    try {
      // 1️⃣ Solicitar permisos de notificaciones
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      // 2️⃣ Configurar notificaciones locales
      await _setupLocalNotifications();

      // 3️⃣ Obtener y guardar token FCM
      await _getAndSaveToken();

      // 4️⃣ Configurar listeners de mensajes
      _setupMessageHandlers();

      // 5️⃣ Listener para actualización de tokens
      _messaging.onTokenRefresh.listen(_updateTokenInDatabase);
      
      // 6️⃣ Forzar actualización del token para asegurar sincronización
      await _forceTokenRefresh();
    } catch (e, stackTrace) {
      developer.log('Error inicializando FCM: $e\n$stackTrace', name: 'FCMService');
    }
  }
  
  /// 🔄 Forzar actualización del token para asegurar sincronización
  Future<void> _forceTokenRefresh() async {
    try {
      // Esperar un poco para que FCM se establezca completamente
      await Future.delayed(const Duration(milliseconds: 500));
      
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInDatabase(token);
      }
    } catch (e) {
      developer.log('Error en force token refresh: $e', name: 'FCMService');
    }
  }

  /// 🔐 Solicitar permisos de notificaciones
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  /// 🔔 Configurar notificaciones locales para mostrar en primer plano
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_stat_kitsu');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Canal de notificación para Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones importantes de KitsuCode',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 🔑 Obtener token FCM y guardarlo en Supabase
  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _updateTokenInDatabase(token);
    } catch (e, stackTrace) {
      developer.log('Error obteniendo token: $e\n$stackTrace', name: 'FCMService');
    }
  }

  /// 💾 Actualizar token en base de datos
  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e, stackTrace) {
      developer.log('Error guardando token en BD: $e\n$stackTrace', name: 'FCMService');
    }
  }

  /// 📬 Configurar listeners para mensajes entrantes
  void _setupMessageHandlers() {
    // Mensaje recibido cuando app está en PRIMER PLANO
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensaje tocado cuando app está en SEGUNDO PLANO o CERRADA
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Verificar si app fue abierta desde una notificación
    _checkInitialMessage();
  }

  /// 🎯 Manejar mensaje cuando app está en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Invalidar providers si es una notificación de nuevo seguidor
    _invalidateProvidersIfNeeded(message.data);
    
    // Mostrar notificación local cuando app está abierta
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// 🔔 Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    try {
      // Convertir data a JSON string para poder recuperarlo después
      final String payloadJson = jsonEncode(message.data);
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificaciones Importantes',
            channelDescription: 'Canal para notificaciones importantes de KitsuCode',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_stat_kitsu',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payloadJson, // Pasar JSON string
      );
    } catch (e) {
      developer.log('Error mostrando notificación local: $e', name: 'FCMService');
    }
  }

  /// 👆 Manejar tap en notificación (app en segundo plano)
  void _handleBackgroundMessageTap(RemoteMessage message) {
    // Invalidar providers si es necesario
    _invalidateProvidersIfNeeded(message.data);
    
    // Navegar a pantalla específica según tipo de notificación
    _handleNotificationNavigation(message.data);
  }
  
  /// 🔄 Invalidar providers según el tipo de notificación
  void _invalidateProvidersIfNeeded(Map<String, dynamic> data) {
    if (_ref == null) return;
    
    final type = data['type'] as String?;
    
    // Si es una notificación de nuevo seguidor, invalidar los providers de seguidores
    if (type == 'new_follower') {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId != null) {
          // Invalidar los providers de listas de seguidores
          _ref.invalidate(followListProvider(FollowListArgs(userId: currentUserId, type: 'followers')));
          _ref.invalidate(followListProvider(FollowListArgs(userId: currentUserId, type: 'following')));
          
          // Invalidar el perfil del usuario para actualizar contadores
          _ref.invalidate(userProfileByIdProvider(currentUserId));
        }
      } catch (e) {
        developer.log('Error invalidando providers: $e', name: 'FCMService');
      }
    }
  }

  ///  Verificar si app fue abierta desde notificación
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _invalidateProvidersIfNeeded(initialMessage.data);
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// 🧭 Manejar navegación según tipo de notificación
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Si no hay router disponible, no podemos navegar
    if (_router == null) return;
    
    final type = data['type'] as String?;

    switch (type) {
      case 'study_reminder':
        // Navegar a home (donde están los desafíos)
        _router.go('/home');
        break;
      case 'new_follower':
        // Navegar al perfil del seguidor
        final followerId = data['follower_id'] as String?;
        if (followerId != null) {
          // Usar go() para tener contexto de navegación completo
          _router.go('/home'); // Primero ir a home para tener navbar
          Future.delayed(const Duration(milliseconds: 300), () {
            _router.push('/profile/$followerId'); // Luego navegar al perfil
          });
        }
        break;
      case 'new_challenge':
        // Navegar a desafíos
        _router.go('/home');
        break;
      case 'news':
        // Navegar a home para ver noticias
        _router.go('/home');
        break;
      case 'streak_reminder':
        // Navegar a perfil para ver racha
        _router.go('/navbar/profile');
        break;
      case 'inactivity_reminder':
        // Navegar a home
        _router.go('/home');
        break;
      default:
        // Por defecto ir a home
        _router.go('/home');
        break;
    }
  }

  /// 👆 Callback cuando usuario toca notificación local
  void _onNotificationTapped(NotificationResponse response) {
    // Recuperar el payload y convertirlo de JSON string a Map
    if (response.payload == null) return;
    
    try {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      // Invalidar providers si es necesario
      _invalidateProvidersIfNeeded(data);
      // Usar el mismo método de navegación que para notificaciones de background
      _handleNotificationNavigation(data);
    } catch (e) {
      developer.log('Error al procesar tap en notificación: $e', name: 'FCMService');
    }
  }

  /// 🗑️ Eliminar token al cerrar sesión
  Future<void> deleteToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('usuarios')
            .update({'fcm_token': null})
            .eq('id', userId);
      }

      await _messaging.deleteToken();
    } catch (e) {
      developer.log('Error eliminando token: $e', name: 'FCMService');
    }
  }

  /// 🔄 Refrescar token manualmente
  Future<void> refreshToken() async {
    try {
      await _messaging.deleteToken();
      await _getAndSaveToken();
    } catch (e) {
      developer.log('Error refrescando token: $e', name: 'FCMService');
    }
  }
}

/// 📬 Handler para mensajes en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Mensaje recibido en background
}
