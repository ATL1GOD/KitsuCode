import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/routes/router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:kitsucode/core/providers/theme_provider.dart';
import 'package:kitsucode/core/providers/app_init_provider.dart';

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
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        routerConfig: router,
        themeMode: themeMode,
        ),
      );
    }
}
