import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Mantener este import

// IMPORTANTE: Importa el NUEVO provider de bootstrap
import 'package:kitsucode/core/providers/bootstrap_provider.dart'; 
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
// appInitProvider ya no es necesario aquí, se ejecutará en segundo plano

const Color _kitsuOrange = Color(0xFFf79126);

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with TickerProviderStateMixin {
  static const String _word = 'KITSUCODE';
  
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  bool _bootstrapDone = false;
  bool _animationDone = false;
  late final ProviderSubscription<AsyncValue<void>> _bootstrapSub;

  void _checkAndNavigate() {
    // La lógica sigue igual: navegar solo cuando AMBOS estén listos.
    // Ahora _animationDone no será 'true' hasta que pasen 3 segundos.
    if (_bootstrapDone && _animationDone) {
      FlutterNativeSplash.remove(); 

      final isLogged = ref.read(authStateProvider).value?.session != null;
      print('SplashView: Navegando. Estado de sesión: $isLogged');

      if (isLogged) {
        context.go('/home');
      } else {
        context.go('/auth');
      }
    }
  }

  void _startAnimation() {
    if (!mounted) return;
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _animationDone = true;
          _checkAndNavigate();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // --- CAMBIO 1: La duración total ahora es de 3 segundos ---
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // <-- CAMBIADO DE 1300ms
    );

    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < _word.length; i++) {
      // --- CAMBIO 2: Ajustar los intervalos para que duren más ---
      // Cada letra empieza un 8% más tarde que la anterior
      final double startTime = (i * 0.08); 
      // Cada letra tarda un 25% de la duración total (750ms) en animarse
      final double endTime = startTime + 0.25; 
      // --- FIN CAMBIO 2 ---

      final curve = CurvedAnimation(
        parent: _controller,
        curve: Interval(
          startTime,
          endTime.clamp(0.0, 1.0), // El clamp es por si acaso
          curve: Curves.easeOut,
        ),
      );
      _fadeAnimations.add(curve);
      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(curve),
      );
    }

    // Lanza la inicialización esencial
    ref.read(bootstrapProvider.notifier);

    // Escucha la finalización del bootstrapProvider
    _bootstrapSub = ref.listenManual<AsyncValue<void>>(bootstrapProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (mounted) {
            setState(() {
              _bootstrapDone = true;
              _checkAndNavigate();
            });
          }
        },
        error: (e, s) {
          print('Error crítico en Bootstrap: $e');
          if (mounted) {
            setState(() {
              _bootstrapDone = true;
              _checkAndNavigate();
            });
          }
        },
      );
    });

    // Inicia la animación de las letras
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bootstrapSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = _word.split('');

    return Scaffold(
      backgroundColor: _kitsuOrange,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              'assets/images/auth/fox_login.png',
              width: 150,
            ),
          ),
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

                  return FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: SlideTransition(
                      position: _slideAnimations[index],
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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