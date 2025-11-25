// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:kitsucode/core/providers/theme_provider.dart';
import 'package:kitsucode/core/providers/app_init_provider.dart';
import 'package:kitsucode/core/widgets/music_manager.dart';
// 🔥 IMPORTAR EL PROVIDER DE FCM
import 'package:kitsucode/features/notifications/provider/fcm_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    // 1. Inicialización General (Bootstrap, etc.)
    ref.listen(appInitProvider, (_, __) {});

    // 2. 🔥 ACTIVAR SISTEMA DE NOTIFICACIONES
    // Usamos 'watch' para mantener vivo el provider. 
    // Como corre en segundo plano, NO congela la pantalla.
    ref.watch(fcmInitializationProvider);

    return OverlaySupport.global(
      child: MusicManager(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          routerConfig: router,
          themeMode: themeMode,
        ),
      ),
    );
  }
}