import 'dart:developer' as developer;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/follow_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoRouter? _router;
  final Ref? _ref;

  FCMService([this._router, this._ref]);

  Future<void> initialize() async {
    try {
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      await _setupLocalNotifications();

      await _getAndSaveToken();

      _setupMessageHandlers();

      _messaging.onTokenRefresh.listen(_updateTokenInDatabase);

      await _forceTokenRefresh();
    } catch (e, stackTrace) {
      developer.log(
        'Error inicializando FCM: $e\n$stackTrace',
        name: 'FCMService',
      );
    }
  }

  Future<void> _forceTokenRefresh() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInDatabase(token);
      }
    } catch (e) {
      developer.log('Error en force token refresh: $e', name: 'FCMService');
    }
  }

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

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_stat_kitsu',
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _updateTokenInDatabase(token);
    } catch (e, stackTrace) {
      developer.log(
        'Error obteniendo token: $e\n$stackTrace',
        name: 'FCMService',
      );
    }
  }

  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e, stackTrace) {
      developer.log(
        'Error guardando token en BD: $e\n$stackTrace',
        name: 'FCMService',
      );
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    _checkInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _invalidateProvidersIfNeeded(message.data);

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    try {
      final String payloadJson = jsonEncode(message.data);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificaciones Importantes',
            channelDescription:
                'Canal para notificaciones importantes de KitsuCode',
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
        payload: payloadJson,
      );
    } catch (e) {
      developer.log(
        'Error mostrando notificación local: $e',
        name: 'FCMService',
      );
    }
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    _invalidateProvidersIfNeeded(message.data);

    _handleNotificationNavigation(message.data);
  }

  void _invalidateProvidersIfNeeded(Map<String, dynamic> data) {
    if (_ref == null) return;

    final type = data['type'] as String?;

    if (type == 'new_follower') {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId != null) {
          _ref.invalidate(
            followListProvider(
              FollowListArgs(userId: currentUserId, type: 'followers'),
            ),
          );
          _ref.invalidate(
            followListProvider(
              FollowListArgs(userId: currentUserId, type: 'following'),
            ),
          );

          _ref.invalidate(userProfileByIdProvider(currentUserId));
        }
      } catch (e) {
        developer.log('Error invalidando providers: $e', name: 'FCMService');
      }
    }
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _invalidateProvidersIfNeeded(initialMessage.data);
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) async {
    if (_router == null) return;

    final type = data['type'] as String?;
    final route = data['route'] as String?; 

    if (type == 'news_update') { 
       if (route != null) {
          if (route.startsWith('http') || route.startsWith('https')) {
            final Uri url = Uri.parse(route);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              developer.log('No se pudo abrir el link: $route', name: 'FCMService');
            }
            return; 
          } 
        
          else {
             _router.go('/home'); 
             Future.delayed(const Duration(milliseconds: 300), () {
               try {
                 _router.push(route); 
               } catch (e) {
                 developer.log('Ruta inválida recibida: $route', name: 'FCMService');
               }
             });
             return;
          }
       }
    }

    switch (type) {
      case 'study_reminder':
        _router.go('/home');
        break;
      case 'new_follower':
        final followerId = data['follower_id'] as String?;
        if (followerId != null) {
          _router.go('/home');
          Future.delayed(const Duration(milliseconds: 300), () {
            _router.push('/profile/$followerId');
          });
        }
        break;
      case 'new_challenge':
        _router.go('/home');
        break;
      case 'news': 
        _router.go('/home');
        break;
      case 'streak_reminder':
        _router.go('/home');
        break;
      case 'inactivity_reminder':
        _router.go('/home');
        break;
      default:
        _router.go('/home');
        break;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(response.payload!);

      _invalidateProvidersIfNeeded(data);

      _handleNotificationNavigation(data);
    } catch (e) {
      developer.log(
        'Error al procesar tap en notificación: $e',
        name: 'FCMService',
      );
    }
  }

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

  Future<void> refreshToken() async {
    try {
      await _messaging.deleteToken();
      await _getAndSaveToken();
    } catch (e) {
      developer.log('Error refrescando token: $e', name: 'FCMService');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
