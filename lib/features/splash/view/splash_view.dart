// lib/features/splash/view/splash_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:kitsucode/core/providers/app_init_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

const Color _kitsuOrange = Color(0xFFf79126);

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with TickerProviderStateMixin {
  bool _initDone = false;
  bool _animationDone = false;

  void _checkAndNavigate() {
    if (_initDone && _animationDone) {
      final isLogged = ref.read(authStateProvider).value?.session != null;
      context.go(isLogged ? '/home' : '/auth');
    }
  }

  @override
  void initState() {
    super.initState();
    // Ocultamos UI nativa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));

    // 1. Lanzamos la inicialización en paralelo
    ref.read(appInitProvider);
    // Escuchamos el estado de inicialización
    ref.listen<AsyncValue<void>>(appInitProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          _initDone = true;
          _checkAndNavigate();
        },
        error: (_, __) {
          // Ante error de init, navega al login
          _initDone = true;
          _checkAndNavigate();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kitsuOrange,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo naranja estático
          Container(color: _kitsuOrange),

          // Animación de texto en el centro
          Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'KITSUCODE',
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  _animationDone = true;
                  _checkAndNavigate();
                },
              ),
            ),
          ),

          // Puedes añadir tu logo si lo deseas en otra posición
        ],
      ),
    );
  }
}
