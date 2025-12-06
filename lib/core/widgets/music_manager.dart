import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

import 'package:kitsucode/core/routes/router.dart';

import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart';

class MusicManager extends ConsumerStatefulWidget {
  final Widget child;

  const MusicManager({super.key, required this.child});

  @override
  ConsumerState<MusicManager> createState() => _MusicManagerState();
}

class _MusicManagerState extends ConsumerState<MusicManager>
    with WidgetsBindingObserver {
  VoidCallback? _routerListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRouterListener();
    });
  }

  void _setupRouterListener() {
    final router = ref.read(routerProvider);

    _routerListener = () {
      try {
        final String location = router.routerDelegate.currentConfiguration.uri
            .toString();

        if (location.contains('/auth') || location == '/') {
          ref.read(audioControllerProvider).stopMusic();
          return;
        }

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
        ref
            .read(routerProvider)
            .routerDelegate
            .removeListener(_routerListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioController = ref.read(audioControllerProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      audioController.pauseMusicAppLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      try {
        final router = ref.read(routerProvider);
        final location = router.routerDelegate.currentConfiguration.uri
            .toString();
        final isInChallenge = ref.read(isInChallengeProvider);

        if (!location.contains('/auth') && location != '/' && !isInChallenge) {
          _checkAndPlayMusic("App Resumida");
        }
      } catch (_) {}
    }
  }

  void _checkAndPlayMusic(String motivo) {
    final langState = ref.read(appBarProvider);
    if (langState.languageName.isNotEmpty) {
      ref
          .read(audioControllerProvider)
          .playBackgroundMusic(langState.languageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapProvider);

    if (!bootstrapState.hasValue ||
        bootstrapState.isLoading ||
        bootstrapState.hasError) {
      return widget.child;
    }

    ref.listen(isInChallengeProvider, (previous, next) {
      final audioController = ref.read(audioControllerProvider);

      if (previous == false && next == true) {
        audioController.stopMusic();
      }

      if (previous == true && next == false) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          try {
            final location = ref
                .read(routerProvider)
                .routerDelegate
                .currentConfiguration
                .uri
                .toString();
            if (location.contains('/auth')) return;
          } catch (_) {}

          _checkAndPlayMusic("Fin de Reto");
        });
      }
    });

    ref.listen(appBarProvider, (previous, next) {
      try {
        final location = ref
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .toString();
        if (location.contains('/auth') || location == '/') return;
      } catch (_) {}

      if (ref.read(isInChallengeProvider)) return;

      if (next.languageName.isNotEmpty) {
        ref
            .read(audioControllerProvider)
            .playBackgroundMusic(next.languageName);
      }
    });

    ref.listen(settingsProvider, (previous, next) {
      next.whenData(
        (_) => ref.read(audioControllerProvider).updateMusicVolume(),
      );
    });

    return widget.child;
  }
}
