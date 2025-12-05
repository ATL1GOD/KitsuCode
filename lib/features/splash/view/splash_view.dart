import 'dart:async';
import 'package:flutter/material.dart' hide ShaderWarmUp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:kitsucode/core/providers/bootstrap_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/connectivity_provider.dart';
import 'package:kitsucode/core/widgets/shader_warmup.dart';

// Asegúrate de que esta ruta sea correcta según tu estructura de carpetas
import 'package:kitsucode/core/routes/router.dart' show setSplashCompleted;
// O si está en core: import 'package:kitsucode/core/routes/router.dart' show setSplashCompleted;

const Color _kitsuOrange = Color(0xFFf79126);

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  static const String _word = 'KITSUCODE';

  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  bool _bootstrapDone = false;
  bool _animationDone = false;
  bool _navigated = false; // Flag de seguridad

  late ProviderSubscription<AsyncValue<void>> _bootstrapSub;

  void _tryNavigate() {
    // 1. Si las pre-condiciones no están listas, esperamos.
    if (!_bootstrapDone || !_animationDone) return;

    // NOTA: No ponemos _navigated = true aquí porque rompería el reintento
    // si la conectividad está 'loading'.

    final connectivityState = ref.read(initialConnectivityProvider);

    connectivityState.when(
      data: (status) {
        // 2. AQUÍ verificamos y bloqueamos la navegación múltiple
        if (_navigated) return;
        _navigated = true;

        // 3. Abrimos el candado del Router
        setSplashCompleted();
        FlutterNativeSplash.remove();

        // 4. Lógica de direccionamiento
        if (status == ConnectivityStatus.offline) {
          context.go('/no-internet');
        } else {
          final isLogged = ref.read(authStateProvider).value?.session != null;
          if (isLogged) {
            context.go('/home');
          } else {
            context.go('/auth');
          }
        }
      },
      loading: () {
        // Si está cargando, reintentamos. Como _navigated sigue false,
        // la función volverá a entrar correctamente.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _tryNavigate();
        });
      },
      error: (_, __) {
        if (_navigated) return;
        _navigated = true;

        setSplashCompleted();
        FlutterNativeSplash.remove();
        context.go('/no-internet');
      },
    );
  }

  void _setupAnimation() {
    const double totalDuration = 3.0;
    const double letterDuration = 0.25;
    const double letterDelay = 0.10;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < _word.length; i++) {
      final start = (i * letterDelay) / totalDuration;
      final end = ((i * letterDelay) + letterDuration) / totalDuration;

      final curved = CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
      );

      _fadeAnimations.add(curved);

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curved),
      );
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _tryNavigate();
      }
    });
  }

  void _listenBootstrap() {
    // Nos aseguramos de inicializar el provider
    ref.read(bootstrapProvider);

    _bootstrapSub = ref.listenManual<AsyncValue<void>>(bootstrapProvider, (
      _,
      next,
    ) {
      next.whenOrNull(
        data: (_) {
          _bootstrapDone = true;
          _tryNavigate();
        },
        error: (_, __) {
          // Incluso con error en bootstrap, intentamos continuar
          // (quizás es error de red que manejaremos en connectivity)
          _bootstrapDone = true;
          _tryNavigate();
        },
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _listenBootstrap();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pequeño delay para suavizar la transición desde el splash nativo
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) _controller.forward();
    });
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
          // 🔥 Shader warm-up: Precompila todos los shaders costosos
          const ShaderWarmUp(),

          Center(
            child: Image.asset(
              'assets/images/auth/fox_login.webp',
              width: 150,
              cacheWidth: 300,
            ),
          ),

          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(letters.length, (i) {
                  return FadeTransition(
                    opacity: _fadeAnimations[i],
                    child: SlideTransition(
                      position: _slideAnimations[i],
                      child: Text(
                        letters[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
