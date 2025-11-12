import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Necesario para detectar la plataforma
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app.dart';

// Route observer global para monitorear cambios de ruta
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// El handler de background DEBE ser una función de nivel superior
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegura que Firebase esté inicializado
  await Firebase.initializeApp();
}

void main() async {
  // --- INICIO: TAREAS DE INICIALIZACIÓN OBLIGATORIAS 

  // 1. Asegura la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase (IMPORTANTE: Diferente para Web y Móvil)
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

  // 3. Configura el handler de background
  // Esto es necesario para recibir notificaciones cuando la app está en background o cerrada
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 4. Carga las variables de entorno
  await dotenv.load(fileName: "assets/.env");

  // 5. Inicializa el *cliente* de Supabase 
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 6. Configuración de UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // --- FIN: TAREAS OBLIGATORIAS 

  // Ejecuta la app dentro de ProviderScope
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}