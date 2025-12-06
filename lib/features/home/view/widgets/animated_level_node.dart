import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

import 'package:visibility_detector/visibility_detector.dart';

class AnimatedLevelNode extends ConsumerStatefulWidget {
  final int levelId;
  final Widget child;

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

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
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
    ref.listen<int?>(newlyUnlockedLevelProvider, (previous, next) async {
      if (next == widget.levelId) {
        while (mounted && !_isVisible) {
          await Future.delayed(const Duration(milliseconds: 200));
        }

        if (!mounted) return;

        ref.read(audioControllerProvider).playLevelUnlock();
        _animationController.forward(from: 0.0);

        ref.read(newlyUnlockedLevelProvider.notifier).state = null;
      }
    });

    return VisibilityDetector(
      key: Key('level-node-${widget.levelId}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;

        final isNowVisible = info.visibleFraction > 0.0;
        if (_isVisible != isNowVisible) {
          _isVisible = isNowVisible;
        }
      },

      child: RepaintBoundary(
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
