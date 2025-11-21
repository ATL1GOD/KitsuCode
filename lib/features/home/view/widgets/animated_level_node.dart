import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

// 1. Importamos VisibilityDetector para saber si REALMENTE se ve la pantalla
import 'package:visibility_detector/visibility_detector.dart';

class AnimatedLevelNode extends ConsumerStatefulWidget {
  final int levelId; // El ID de este nivel
  final Widget child; // La "bolita" (LevelNode)

  const AnimatedLevelNode({
    super.key,
    required this.levelId,
    required this.child,
  });

  @override
  ConsumerState<AnimatedLevelNode> createState() => _AnimatedLevelNodeState();
}

class _AnimatedLevelNodeState extends ConsumerState<AnimatedLevelNode>
    with SingleTickerProviderStateMixin {
      
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  
  // 2. Variable para rastrear la visibilidad real
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en el provider
    ref.listen<int?>(newlyUnlockedLevelProvider, (previous, next) async {
      if (next == widget.levelId) {
        
        // --- 3. ESPERA INTELIGENTE ---
        // En lugar de confiar en la ruta, confiamos en si el widget se ve.
        // Mientras '_isVisible' sea false (porque estás en la pantalla de Success),
        // este bucle mantiene el código en pausa.
        while (mounted && !_isVisible) {
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // Si el widget sigue vivo después de esperar...
        if (!mounted) return;

        // --- 4. AHORA SÍ: SONIDO Y ANIMACIÓN ---
        // Se ejecuta justo cuando la pantalla de Home se hace visible.
        ref.read(audioControllerProvider).playLevelUnlock();
        _animationController.forward(from: 0.0);
        
        // Limpiamos el provider
        ref.read(newlyUnlockedLevelProvider.notifier).state = null; 
      }
    });

    // 5. Envolvemos todo en VisibilityDetector
    return VisibilityDetector(
      key: Key('level-node-${widget.levelId}'), // Clave única necesaria
      onVisibilityChanged: (info) {
        if (!mounted) return;
        // Si la fracción visible es > 0, es que el usuario ya ve la pantalla
        final isNowVisible = info.visibleFraction > 0.0;
        if (_isVisible != isNowVisible) {
          // Actualizamos la variable de control (sin setState para evitar rebuilds innecesarios,
          // ya que solo la usamos para controlar el bucle while)
          _isVisible = isNowVisible;
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}