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
  late AnimationController _mainController;
  late AnimationController _effectsController;

  late int _previousValue;
  late int _displayValue;

  bool _playStreakFire = false;
  bool _playLifeEffect = false;
  bool _playTrophyEffect = false;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _displayValue = widget.value;

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _effectsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedStatBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _displayValue) {
      _startAnimation(oldWidget.value, widget.value);

      if (widget.type == StatType.streak && widget.value > oldWidget.value) {
        setState(() => _playStreakFire = true);
        _effectsController.forward(from: 0);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _playStreakFire = false);
            _effectsController.reset();
          }
        });
      }

      if (widget.type == StatType.life && widget.value < oldWidget.value) {
        setState(() => _playLifeEffect = true);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _playLifeEffect = false);
        });
      }

      if (widget.type == StatType.trophy && widget.value > oldWidget.value) {
        setState(() => _playTrophyEffect = true);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _playTrophyEffect = false);
        });
      }
    }
  }

  void _startAnimation(int from, int to) {
    _previousValue = from;
    _mainController.forward(from: 0);
    setState(() => _displayValue = to);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.borderColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _effectsController]),
      builder: (_, __) {
        final t = _mainController.value;
        final showingOld = t < 0.5;
        final localT = showingOld ? (t / 0.5) : ((1 - t) / 0.5);

        final angle = localT * math.pi;
        final scale = 1.0 + 0.40 * math.sin(t * math.pi);
        final numDisplayed = showingOld ? _previousValue : _displayValue;

        final fireProgress = _effectsController.value.clamp(0.0, 1.0);

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

        double shake = 0;
        double lifeScale = 1.0;
        Color iconColor = widget.color;

        if (_playLifeEffect && widget.type == StatType.life) {
          shake = math.sin(t * math.pi * 8) * 4;
          lifeScale = 1.0 + (0.25 * math.sin(t * math.pi * 2));
          iconColor = Color.lerp(Colors.red[700]!, widget.color, t)!;
        }

        double trophyBounce = 0;
        double trophyScale = 1.0;
        double trophyRotation = 0;

        if (_playTrophyEffect && widget.type == StatType.trophy) {
          trophyBounce = -math.sin(t * math.pi) * 6;
          trophyScale = 1.0 + (0.3 * math.sin(t * math.pi));
          trophyRotation = math.sin(t * math.pi * 2) * 0.15;
          iconColor = Color.lerp(Colors.amber[400]!, widget.color, t)!;
        }

        return RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primaryColor.withAlpha(230),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(128),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: primaryColor.withAlpha(77),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(shake, trophyBounce),
                        child: Transform.scale(
                          scale: widget.type == StatType.life
                              ? lifeScale
                              : trophyScale,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
          ),
        );
      },
    );
  }
}
