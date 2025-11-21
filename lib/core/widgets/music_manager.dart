import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';
import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart';

class MusicManager extends ConsumerStatefulWidget {
  final Widget child;

  const MusicManager({super.key, required this.child});

  @override
  ConsumerState<MusicManager> createState() => _MusicManagerState();
}

class _MusicManagerState extends ConsumerState<MusicManager> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final audioController = ref.read(audioControllerProvider);
      
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          audioController.pauseMusicAppLifecycle();
          break;
          
        case AppLifecycleState.resumed:
          final currentLang = ref.read(appBarProvider).languageName;
          if (currentLang.isNotEmpty) {
            audioController.playBackgroundMusic(currentLang);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      // Fallo silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapProvider);
    
    if (!bootstrapState.hasValue || bootstrapState.isLoading || bootstrapState.hasError) {
      return widget.child;
    }

    // Listener del estado del reto
    ref.listen(isInChallengeProvider, (previous, next) {
      if (next == false && previous == true) {
        // Salió del reto, reanudar música
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          
          final audioController = ref.read(audioControllerProvider);
          final currentLang = ref.read(appBarProvider).languageName;
          
          if (currentLang.isNotEmpty) {
            audioController.playBackgroundMusic(currentLang);
          }
        });
      }
    });

    // Listener del AppBar (cambios de lenguaje)
    ref.listen(appBarProvider, (previous, next) {
      if (next.languageName.isNotEmpty && 
          previous?.languageName != next.languageName) {
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