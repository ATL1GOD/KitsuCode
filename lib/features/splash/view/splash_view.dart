import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:kitsucode/core/providers/bootstrap_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/core/providers/connectivity_provider.dart';

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
  bool _navigated = false;

  late ProviderSubscription<AsyncValue<void>> _bootstrapSub;

  void _tryNavigate() {
    if (_navigated) return;
    if (!_bootstrapDone || !_animationDone) return;

    _navigated = true;
    FlutterNativeSplash.remove();

    // 🔥 VERIFICAR CONECTIVIDAD ANTES DE NAVEGAR
    final connectivityState = ref.read(initialConnectivityProvider);

    connectivityState.when(
      data: (status) {
        if (status == ConnectivityStatus.offline) {
          // Si no hay internet, ir a NoInternetView
          context.go('/no-internet');
          return;
        }

        // Si hay internet, navegación normal según autenticación
        final isLogged = ref.read(authStateProvider).value?.session != null;
        if (isLogged) {
          context.go('/home');
        } else {
          context.go('/auth');
        }
      },
      loading: () {
        // Mientras verifica conectividad, esperar un poco
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _tryNavigate(); // Reintentar
        });
      },
      error: (_, __) {
        // Si hay error verificando, asumir sin internet
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

    // 🔥 LA CLAVE: ESPERAR A QUE LA SPLASH NATIVA SE HAYA IDO COMPLETAMENTE
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 120));
      // ⬆ Pequeño delay para asegurar que ya no está la splash nativa
      _controller.forward();
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
          Center(
            child: Image.asset('assets/images/auth/fox_login.webp', width: 150),
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
