import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kitsucode/core/providers/app_init_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

const Color _kitsuOrange = Color(0xFFf79126);

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with TickerProviderStateMixin {
  static const String _word = 'KITSUCODE';
  
  // Lista de controladores de animación para cada letra
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;

  bool _initDone = false;
  bool _animationDone = false;
  late final ProviderSubscription<AsyncValue<void>> _initSub;

  void _checkAndNavigate() {
    if (_initDone && _animationDone) {
      final isLogged = ref.read(authStateProvider).value?.session != null;
      context.go(isLogged ? '/home' : '/auth');
    }
  }

  // Método para manejar la animación secuencial de las letras
  void _startAnimation() async {
  for (int i = 0; i < _word.length; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return; // Si la pantalla ya no existe, sal del método
    _controllers[i].forward();
  }

  await Future.delayed(const Duration(milliseconds: 500));
  if (!mounted) return;

  setState(() {
    _animationDone = true;
    _checkAndNavigate();
  });
}

  @override
  void initState() {
    super.initState();

    // Inicializa los controladores de animación
    // Se usa 'SingleTickerProviderStateMixin' para 'vsync: this'
    _controllers = List.generate(
      _word.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400), // Duración de la aparición de cada letra
      ),
    );

    // Inicializa las animaciones de deslizamiento (Offset: desliza 0.5 unidades hacia abajo)
    _animations = List.generate(
      _word.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5), // Empieza ligeramente abajo (0.5 de su altura)
        end: Offset.zero, // Termina en su posición normal (0)
      ).animate(CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.easeOut, // Curva de animación suave
      )),
    );

    // Ajustes de UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));

    // Lanza la inicialización de datos (carga en segundo plano)
    ref.read(appInitProvider);

    // Escucha la finalización del appInitProvider
    _initSub = ref.listenManual<AsyncValue<void>>(appInitProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          _initDone = true;
          _checkAndNavigate();
        },
        error: (_, __) {
          _initDone = true;
          _checkAndNavigate();
        },
      );
    });

    // Inicia la animación de las letras
    _startAnimation();
  }

  @override
  void dispose() {
    // Es crucial hacer dispose de todos los controladores de animación
    for (var controller in _controllers) {
      controller.dispose();
    }
    _initSub.close(); // Cerramos la suscripción manual de Riverpod
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Separa la palabra en letras para animar cada una individualmente
    final letters = _word.split('');

    return Scaffold(
      backgroundColor: _kitsuOrange,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen del zorro centrada
          Center(
            child: Image.asset(
              'assets/images/auth/fox_login.png',
              width: 150,
            ),
          ),
          // Texto animado en la parte inferior
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: letters.asMap().entries.map((entry) {
                  final index = entry.key;
                  final letter = entry.value;

                  // Usa FadeTransition y SlideTransition para cada letra
                  return FadeTransition(
                    opacity: _controllers[index],
                    child: SlideTransition(
                      position: _animations[index],
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32, // Un poco más grande para el efecto
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}