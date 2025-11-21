import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

class MusicManager extends ConsumerStatefulWidget {
  final Widget child;

  const MusicManager({super.key, required this.child});

  @override
  ConsumerState<MusicManager> createState() => _MusicManagerState();
}

class _MusicManagerState extends ConsumerState<MusicManager> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // Registramos el observador para detectar ciclo de vida (minimizar/cerrar)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ⭐ 1. CICLO DE VIDA: Salir y Volver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final audioController = ref.read(audioControllerProvider);
      
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          // Pausar al salir para ahorrar batería
          audioController.pauseMusicAppLifecycle();
          break;
          
        case AppLifecycleState.resumed:
          // 🔥 CRUCIAL: Al volver a la app, leemos el lenguaje actual y forzamos el play.
          final currentLang = ref.read(appBarProvider).languageName;
          if (currentLang.isNotEmpty) {
            audioController.playBackgroundMusic(currentLang);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('MusicLifecycle Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // GUARDIA DE SEGURIDAD (Para no crashear Supabase al inicio si reinicias rápido)
    final bootstrapState = ref.watch(bootstrapProvider);
    
    // Si hay error, sigue cargando, o no tiene valor -> NO hacemos nada aún.
    if (!bootstrapState.hasValue || bootstrapState.isLoading || bootstrapState.hasError) {
      return widget.child;
    }

    // ---------------------------------------------------------
    // ZONA SEGURA: Aquí Supabase YA está inicializado
    // ---------------------------------------------------------

    // ⭐ 2. LISTENER "INSISTENTE"
    // Escuchamos al AppBarProvider.
    ref.listen(appBarProvider, (previous, next) {
      // 🔥 CAMBIO CLAVE: Quitamos la condición 'if (previous != next)'.
      // Antes, si volvías de un juego y el lenguaje seguía siendo "Python", no hacía nada.
      // Ahora, cada vez que el AppBar se actualice (ej. recuperar vidas, o simplemente recargar),
      // intentamos poner la música.
      
      // Gracias a la lógica en audio_provider, si ya está sonando NO se reinicia (sin cortes),
      // pero si estaba detenida, ¡volverá a sonar!
      if (next.languageName.isNotEmpty) {
        ref.read(audioControllerProvider).playBackgroundMusic(next.languageName);
      }
    });

    // Listener de volumen (Ajustes)
    ref.listen(settingsProvider, (previous, next) {
      next.whenData((_) {
        ref.read(audioControllerProvider).updateMusicVolume();
      });
    });

    return widget.child;
  }
}