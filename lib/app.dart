import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:kitsucode/core/providers/theme_provider.dart';
import 'package:kitsucode/core/providers/app_init_provider.dart';
// 1. Importamos el MusicManager
import 'package:kitsucode/core/widgets/music_manager.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    // Asegura que la inicialización de la app se ejecute
    ref.listen(appInitProvider, (previous, next) {
      // Solo queremos que el provider se ejecute.
    });

    return OverlaySupport.global(
      // 2. Envolvemos MaterialApp con MusicManager
      // Esto asegura que el "oído" de la música esté activo en TODA la app
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