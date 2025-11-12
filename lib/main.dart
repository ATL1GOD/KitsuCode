import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Necesario para detectar la plataforma
import 'package:flutter/foundation.dart' show kIsWeb;

// Importamos el handler de background de FCM
import 'package:kitsucode/features/notifications/service/fcm_service.dart';

// Importamos el widget principal de la App
import 'app.dart';

// El RouteObserver se queda igual
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// El handler de background DEBE ser una función de nivel superior
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase aquí también para que
  // el handler de background funcione cuando la app está terminada.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  // --- INICIO: TAREAS DE INICIALIZACIÓN OBLIGATORIAS (RÁPIDAS) ---

  // 1. Asegura la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase (es rápido, solo configura la conexión)
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
  // (Nota: El 'firebaseMessagingBackgroundHandler' real está en fcm_service.dart)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 4. Carga las variables de entorno (rápido, lee un archivo)
  await dotenv.load(fileName: "assets/.env");

  // 5. Inicializa el *cliente* de Supabase (rápido, no espera la sesión)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 6. Configuración de UI (rápido, síncrono)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // --- FIN: TAREAS OBLIGATORIAS ---

  // ¡YA NO HAY 'await' DE RED NI 'ProviderContainer' MANUAL!
  // Simplemente ejecutamos la app. ProviderScope se encargará del resto.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}