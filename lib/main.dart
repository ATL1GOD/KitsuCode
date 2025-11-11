import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kitsucode/features/notifications/service/local_notification_service.dart'; 
import 'package:kitsucode/features/notifications/service/fcm_service.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'app.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Configurar handler de mensajes en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Inicializa el servicio de notificaciones locales
  final localNotificationService = LocalNotificationService();
  await localNotificationService.init();
  
  // Inicializar Supabase PRIMERO
  await dotenv.load(fileName: "assets/.env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Crea un ProviderContainer para actualizar Supabase ANTES de correr la app
  final container = ProviderContainer();
  try {
    // Espera a que se cargue la sesión de usuario
    await container.read(authStateProvider.future);
    await container.read(settingsProvider.future);
    
    // Inicializar FCM en paralelo con otros procesos (no bloqueante)
    final fcmService = container.read(fcmServiceProvider);
    fcmService.initialize().catchError((e) {
      debugPrint('Error inicializando FCM: $e');
    });
  } catch (e) {
    debugPrint('Error al cargar datos iniciales: $e');
    // Intentar inicializar FCM incluso si hay errores anteriores
    try {
      final fcmService = container.read(fcmServiceProvider);
      fcmService.initialize();
    } catch (fcmError) {
      debugPrint('Error inicializando FCM: $fcmError');
    }
  }

  runApp(ProviderScope(parent: container, child: const MyApp()));
}
