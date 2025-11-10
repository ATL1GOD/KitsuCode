import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Duración del "pop"
    );
    
    // Animación de escala: 1.0 -> 1.4 -> 1.0
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack, // Efecto "pop" elástico
      ),
    );

    // Cuando la animación de "crecer" termina, la revertimos
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
    // --- ¡LA MAGIA! ---
    // 'ref.listen' es para "side-effects" como disparar animaciones
    ref.listen<int?>(newlyUnlockedLevelProvider, (previous, next) {
      // Si el nuevo ID es el mío... ¡me animo!
      if (next == widget.levelId) {
        _animationController.forward(from: 0.0);
        // Limpiamos el provider para no animar de nuevo si se reconstruye
        ref.read(newlyUnlockedLevelProvider.notifier).state = null; 
      }
    });
    // --- FIN DE LA MAGIA ---

    // Envolvemos la bolita en la animación de escala
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}