import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Mantener este import

import 'package:kitsucode/core/providers/app_init_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

const Color _kitsuOrange = Color(0xFFf79126);

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  // Asegúrate de que SingleTickerProviderStateMixin esté incluido
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with TickerProviderStateMixin{ // << AÑADIR with SingleTickerProviderStateMixin AQUÍ
  static const String _word = 'KITSUCODE';
  
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;

  bool _initDone = false;
  bool _animationDone = false;
  late final ProviderSubscription<AsyncValue<void>> _initSub;

  void _checkAndNavigate() {
    if (_initDone && _animationDone) {
      // 1. Siempre remover el splash nativo
      FlutterNativeSplash.remove(); 

      final isLogged = ref.read(authStateProvider).value?.session != null;
      print('Estado de sesión: $isLogged'); // Registro para depuración

      // 2. Navegar según el estado de autenticación
      if (isLogged) {
        context.go('/home'); // Redirigir al Home si está autenticado
      } else {
        context.go('/auth'); // Redirigir al flujo de autenticación si no está autenticado
      }
    }
  }

  void _startAnimation() async {
    // ⚠️ AÑADIR ESTE CHEQUEO PARA PREVENIR EL CRASH ⚠️
    if (!mounted) return; 

    // 1. Inicia las animaciones de forma secuencial
    for (int i = 0; i < _word.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100)); 
      
      // CHEQUEO ADICIONAL ANTES DE LLAMAR forward
      if (!mounted) return; 
      _controllers[i].forward();
    }

    // 2. Espera un poco
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Marca la animación como finalizada y chequea
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
    // Si la inicialización falla aquí, el crash ocurre. Asegúrate de que el mixin esté arriba.
    _controllers = List.generate(
      _word.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    // Inicializa las animaciones de deslizamiento
    _animations = List.generate(
      _word.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5), 
        end: Offset.zero, 
      ).animate(CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.easeOut,
      )),
    );

    // [Ajustes de UI] ... (esto está bien)

    // Lanza la inicialización
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
    // [El código de build sigue igual]
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