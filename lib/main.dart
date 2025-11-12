import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Necesario para detectar la plataforma
import 'package:flutter/foundation.dart' show kIsWeb; 

import 'package:kitsucode/features/notifications/service/local_notification_service.dart'; 
import 'package:kitsucode/features/notifications/service/fcm_service.dart';
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'app.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // esto sirrve para ver si estamos en web o movil
  if (kIsWeb) {
    // Si estamos en la Web, usa esta configuración explícita
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB7yxHwozMQ0QVuTEO_SYliT1y9Zyn7iE4",
        authDomain: "kitsucode-e663f.firebaseapp.com",
        projectId: "kitsucode-e663f",
        storageBucket: "kitsucode-e663f.firebasestorage.app",
        messagingSenderId: "867513491057",
        appId: "1:867513491057:web:69d5c82ab55a5ba1dc05d0"
      ),
    );
  } else {
    // Si estamos en móvil (Android/iOS), usa el método normal  
    await Firebase.initializeApp();
  }
  // fIN
  
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

    // AHORA SÍ ESPERAMOS a que FCM termine y guarde el token
    final fcmService = container.read(fcmServiceProvider);
    await fcmService.initialize(); // <-- ¡ASÍ DEBE QUEDAR!
    // fin 

  } catch (e) {
    debugPrint('Error al cargar datos iniciales: $e');
    // Intentar inicializar FCM incluso si hay errores anteriores
    try {
      final fcmService = container.read(fcmServiceProvider);
      // porque si el primer try falla, es menos crítico.
      fcmService.initialize();
    } catch (fcmError) {
      debugPrint('Error inicializando FCM: $fcmError');
    }
  }

  runApp(ProviderScope(parent: container, child: const MyApp()));
}