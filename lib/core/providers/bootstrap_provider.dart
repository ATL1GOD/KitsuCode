// lib/core/providers/bootstrap_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// El handler de background DEBE estar aquí o en main.dart (nivel superior)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegura que Firebase esté inicializado
  // Nota: Es posible que necesites la configuración web aquí también si usas web
  await Firebase.initializeApp();
}

///
/// Provider para las tareas de inicialización ESENCIALES y BLOQUEANTES.
/// La app no puede funcionar sin que esto se complete.
/// La SplashView DEBE esperar a este provider.
///
final bootstrapProvider = AsyncNotifierProvider<BootstrapNotifier, void>(() {
  return BootstrapNotifier();
});

class BootstrapNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    debugPrint('BootstrapProvider: Inicia carga esencial...');

    // 1. Inicializa Firebase
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB7yxHwozMQ0QVuTEO_SYliT1y9Zyn7iE4",
          authDomain: "kitsucode-e663f.firebaseapp.com",
          projectId: "kitsucode-e663f",
          storageBucket: "kitsucode-e663f.firebasestorage.app",
          messagingSenderId: "867513491057",
          appId: "1:867513491057:web:69d5c82ab55a5ba1dc05d0",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint('BootstrapProvider: Firebase listo.');

    // 2. Configura el handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('BootstrapProvider: Handler de background listo.');

    // 3. Carga las variables de entorno
    await dotenv.load(fileName: "assets/.env");
    debugPrint('BootstrapProvider: .env listo.');

    // 4. Inicializa Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('BootstrapProvider: Supabase listo.');

    // 5. Configuración de UI
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    debugPrint('BootstrapProvider: UI (orientación) lista.');
    
    debugPrint('BootstrapProvider: Carga esencial completada.');
    
    // NOTA: Tu appInitProvider (no esencial) ahora puede empezar
    // si lo hacemos depender de este.
  }
}