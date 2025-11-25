import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';
// Necesitamos el router para detectar si estamos en Login
import 'package:kitsucode/core/routes/router.dart';
// Tu provider de retos
import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart';

class MusicManager extends ConsumerStatefulWidget {
  final Widget child;

  const MusicManager({super.key, required this.child});

  @override
  ConsumerState<MusicManager> createState() => _MusicManagerState();
}

class _MusicManagerState extends ConsumerState<MusicManager> with WidgetsBindingObserver {
  VoidCallback? _routerListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Iniciamos el espía de rutas después de que cargue el frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRouterListener();
    });
  }

  void _setupRouterListener() {
    final router = ref.read(routerProvider);
    
    _routerListener = () {
      try {
        final String location = router.routerDelegate.currentConfiguration.uri.toString();
        
        // 🛑 1. ZONA PROHIBIDA (LOGIN/REGISTRO)
        // Si estamos en auth o raíz, MATAMOS la música sin importar nada más.
        if (location.contains('/auth') || location == '/') {
          ref.read(audioControllerProvider).stopMusic();
          return;
        }

        // ✅ 2. ZONA SEGURA (HOME)
        // Si estamos en Home y NO estamos en un reto, verificamos la música.
        if (location == '/home' || location.startsWith('/home')) {
           final isInChallenge = ref.read(isInChallengeProvider);
           if (!isInChallenge) {
             _checkAndPlayMusic("Router: Navegación a Home");
           }
        }
      } catch (e) {
        debugPrint("Error MusicManager router: $e");
      }
    };

    router.routerDelegate.addListener(_routerListener!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_routerListener != null) {
      try {
        ref.read(routerProvider).routerDelegate.removeListener(_routerListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  // Ciclo de vida (Minimizar/Cerrar app)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioController = ref.read(audioControllerProvider);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      audioController.pauseMusicAppLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      // Al volver, SOLO reanudamos si NO estamos en login y NO estamos en reto
      try {
        final router = ref.read(routerProvider);
        final location = router.routerDelegate.currentConfiguration.uri.toString();
        final isInChallenge = ref.read(isInChallengeProvider);

        if (!location.contains('/auth') && location != '/' && !isInChallenge) {
           _checkAndPlayMusic("App Resumida");
        }
      } catch (_) {}
    }
  }

  // Helper para tocar música de forma segura
  void _checkAndPlayMusic(String motivo) {
    final langState = ref.read(appBarProvider);
    if (langState.languageName.isNotEmpty) {
      ref.read(audioControllerProvider).playBackgroundMusic(langState.languageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapProvider);
    
    if (!bootstrapState.hasValue || bootstrapState.isLoading || bootstrapState.hasError) {
      return widget.child;
    }

    // --- LISTENERS ---

    // 1. CONTROL DE RETOS (Entrar/Salir)
    ref.listen(isInChallengeProvider, (previous, next) {
      final audioController = ref.read(audioControllerProvider);

      // A) Entrando al reto -> STOP
      if (previous == false && next == true) {
        audioController.stopMusic();
      }
      
      // B) Saliendo del reto -> PLAY
      if (previous == true && next == false) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          // Verificamos ruta (por si acaso salió directo al login)
          try {
             final location = ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
             if (location.contains('/auth')) return;
          } catch (_) {}

          _checkAndPlayMusic("Fin de Reto");
        });
      }
    });

    // 2. CAMBIO DE LENGUAJE (Solo si estamos en Home y Logueados)
    ref.listen(appBarProvider, (previous, next) {
      // Guardia: Si estamos en Login, ignorar.
      try {
        final location = ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
        if (location.contains('/auth') || location == '/') return;
      } catch (_) {}

      // Guardia: Si estamos en Reto, ignorar.
      if (ref.read(isInChallengeProvider)) return;

      if (next.languageName.isNotEmpty) {
        ref.read(audioControllerProvider).playBackgroundMusic(next.languageName);
      }
    });

    // 3. VOLUMEN
    ref.listen(settingsProvider, (previous, next) {
      next.whenData((_) => ref.read(audioControllerProvider).updateMusicVolume());
    });

    return widget.child;
  }
}