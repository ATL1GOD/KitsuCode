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

    // 1) Firebase (ÚNICO BLOQUEANTE)
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
    debugPrint('Bootstrap: Firebase listo');

    // 2) dotenv DEBE CARGARSE ANTES DE Supabase
    await dotenv.load(fileName: "assets/.env");
    debugPrint('Bootstrap: .env listo');

    // 3) Supabase (YA CON .env cargado)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('Bootstrap: Supabase listo');

    // 4) UI
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    debugPrint('Bootstrap: UI lista');

    // 5) Handler FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('Bootstrap: Handler de background listo');

    debugPrint('Bootstrap: COMPLETADO ✓ (Firebase + dotenv + Supabase + UI)');
  }
}
