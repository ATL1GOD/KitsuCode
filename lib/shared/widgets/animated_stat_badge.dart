import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum StatType { streak, trophy, life }

class AnimatedStatBadge extends StatefulWidget {
  final int value;
  final IconData icon;
  final Color color;
  final StatType type;
  final Color? borderColor;

  const AnimatedStatBadge({
    super.key,
    required this.value,
    required this.icon,
    required this.color,
    required this.type,
    this.borderColor,
  });

  @override
  State<AnimatedStatBadge> createState() => _AnimatedStatBadgeState();
}

class _AnimatedStatBadgeState extends State<AnimatedStatBadge>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _popController;
  late AnimationController _streakFireController;
  late AnimationController _lifeLossController;
  late AnimationController _trophyGainController; // 🏆 NEW

  late int _previousValue;
  late int _displayValue;

  bool _playStreakFire = false; // 🔥
  bool _lifeLoss = false; // 💔
  bool _trophyGain = false; // 🏆 NEW

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _displayValue = widget.value;

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650), // Aumentado de 450 a 650
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650), // Aumentado de 450 a 650
    );

    _streakFireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200), // Aumentado de 1800 a 2200
    );

    _lifeLossController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // Aumentado de 550 a 750
    );

    _trophyGainController = AnimationController( // 🏆 NEW
      vsync: this,
      duration: const Duration(milliseconds: 800), // Aumentado de 600 a 800
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedStatBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _displayValue) {
      _startAnimation(oldWidget.value, widget.value);

      // 🔥 streak increase
      if (widget.type == StatType.streak && widget.value > oldWidget.value) {
        setState(() => _playStreakFire = true);
        _streakFireController.forward(from: 0);

        Future.delayed(const Duration(milliseconds: 2200), () { // Actualizado de 1800 a 2200
          if (mounted) {
            setState(() => _playStreakFire = false);
            _streakFireController.reset();
          }
        });
      }

      // 💔 life decrease shake
      if (widget.type == StatType.life && widget.value < oldWidget.value) {
        setState(() => _lifeLoss = true);
        _lifeLossController.forward(from: 0);

        Future.delayed(const Duration(milliseconds: 750), () { // Actualizado de 550 a 750
          if (mounted) {
            setState(() => _lifeLoss = false);
            _lifeLossController.reset();
          }
        });
      }

      // 🏆 trophy increase celebration
      if (widget.type == StatType.trophy && widget.value > oldWidget.value) {
        setState(() => _trophyGain = true);
        _trophyGainController.forward(from: 0);

        Future.delayed(const Duration(milliseconds: 800), () { // Actualizado de 600 a 800
          if (mounted) {
            setState(() => _trophyGain = false);
            _trophyGainController.reset();
          }
        });
      }
    }
  }

  void _startAnimation(int from, int to) {
    _previousValue = from;
    _flipController.forward(from: 0);
    _popController.forward(from: 0);
    setState(() => _displayValue = to);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _popController.dispose();
    _streakFireController.dispose();
    _lifeLossController.dispose();
    _trophyGainController.dispose(); // 🏆 NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.borderColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_flipController, _streakFireController, _lifeLossController, _trophyGainController]),
      builder: (_, __) {
        final t = _flipController.value;
        final showingOld = t < 0.5;
        final localT = showingOld ? (t / 0.5) : ((1 - t) / 0.5);

        final angle = localT * math.pi;
        final scale = 1.0 + 0.40 * math.sin(t * math.pi);
        final numDisplayed = showingOld ? _previousValue : _displayValue;

        // 🔥 Fire animation progress
        final fireProgress = _streakFireController.value.clamp(0.0, 1.0);
        
        double lottieOpacity = 0.0;
        if (_playStreakFire && widget.type == StatType.streak) {
          if (fireProgress < 0.15) {
            lottieOpacity = (fireProgress / 0.15).clamp(0.0, 1.0);
          } else if (fireProgress > 0.85) {
            lottieOpacity = ((1.0 - fireProgress) / 0.15).clamp(0.0, 1.0);
          } else {
            lottieOpacity = 1.0;
          }
        }

        double iconOpacity = 1.0;
        if (_playStreakFire && widget.type == StatType.streak) {
          if (fireProgress < 0.15) {
            iconOpacity = (1.0 - (fireProgress / 0.15)).clamp(0.0, 1.0);
          } else if (fireProgress > 0.85) {
            iconOpacity = ((fireProgress - 0.85) / 0.15).clamp(0.0, 1.0);
          } else {
            iconOpacity = 0.0;
          }
        }

        // 💔 Life loss animation
        final lifeAnim = _lifeLossController.value;
        double shake = 0;
        double lifeScale = 1.0;
        Color iconColor = widget.color;

        if (_lifeLoss && widget.type == StatType.life) {
          // Shake effect: vibra de lado a lado
          shake = math.sin(lifeAnim * math.pi * 8) * 5;
          // Pulse effect: se encoge y crece
          lifeScale = 1.0 + (0.3 * math.sin(lifeAnim * math.pi * 2));
          // Color flash: parpadea en rojo
          iconColor = Color.lerp(
            Colors.red[700]!,
            widget.color,
            lifeAnim
          )!;
        }

        // 🏆 Trophy gain animation
        final trophyAnim = _trophyGainController.value;
        double trophyBounce = 0;
        double trophyScale = 1.0;
        double trophyRotation = 0;

        if (_trophyGain && widget.type == StatType.trophy) {
          // Bounce effect: rebota hacia arriba
          trophyBounce = -math.sin(trophyAnim * math.pi) * 8;
          // Scale effect: crece y vuelve a tamaño normal
          trophyScale = 1.0 + (0.4 * math.sin(trophyAnim * math.pi));
          // Rotation: gira ligeramente
          trophyRotation = math.sin(trophyAnim * math.pi * 2) * 0.2;
          // Sparkle color: brilla en dorado
          iconColor = Color.lerp(
            Colors.amber[400]!,
            widget.color,
            trophyAnim
          )!;
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // base badge
            Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.9),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🎯 icon with animations (life, trophy)
                    Transform.translate(
                      offset: Offset(shake, trophyBounce),
                      child: Transform.scale(
                        scale: widget.type == StatType.life ? lifeScale : trophyScale,
                        child: Transform.rotate(
                          angle: trophyRotation,
                          child: Opacity(
                            opacity: iconOpacity,
                            child: Icon(
                              widget.icon,
                              color: iconColor,
                              size: 29,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateX(showingOld ? angle : -angle),
                      child: Text(
                        numDisplayed.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black87,
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 streak fire lottie
            if (_playStreakFire && widget.type == StatType.streak)
              Positioned(
                left: -8,
                top: -15,
                child: Opacity(
                  opacity: lottieOpacity,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      'assets/lottie/streak_fire.json',
                      repeat: false,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}