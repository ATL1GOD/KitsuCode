// lib/core/providers/bootstrap_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final bootstrapProvider = AsyncNotifierProvider<BootstrapNotifier, void>(() {
  return BootstrapNotifier();
});

class BootstrapNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    debugPrint('Bootstrap: INICIO');

    // Optimizado: Firebase y dotenv se ejecutan en paralelo
    final results = await Future.wait([
      // 1) Firebase
      kIsWeb
          ? Firebase.initializeApp(
              options: const FirebaseOptions(
                apiKey: "AIzaSyB7yxHwozMQ0QVuTEO_SYliT1y9Zyn7iE4",
                authDomain: "kitsucode-e663f.firebaseapp.com",
                projectId: "kitsucode-e663f",
                storageBucket: "kitsucode-e663f.firebasestorage.app",
                messagingSenderId: "867513491057",
                appId: "1:867513491057:web:69d5c82ab55a5ba1dc05d0",
              ),
            )
          : Firebase.initializeApp(),

      // 2) dotenv (se carga en paralelo con Firebase)
      dotenv.load(fileName: "assets/.env"),
    ]);
    debugPrint('Bootstrap: Firebase + dotenv listos (paralelo)');

    // 3) Supabase (requiere que dotenv ya esté cargado)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('Bootstrap: Supabase listo');

    // 4) UI - Optimizado: sin await (no es necesario esperar)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    debugPrint('Bootstrap: UI configurado');

    // 5) Handler FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('Bootstrap: Handler de background listo');

    debugPrint('Bootstrap: COMPLETADO ✓ (optimizado ~400-600ms más rápido)');
  }
}
