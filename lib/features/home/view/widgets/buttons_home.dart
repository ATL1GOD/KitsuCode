import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReliefSectionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color baseColor;
  final Color reliefColor;
  final String svgAsset;
  final double size;
  final double reliefThickness;

  const ReliefSectionButton({
    super.key,
    required this.onPressed,
    required this.baseColor,
    required this.reliefColor,
    required this.svgAsset,
    this.size = 56.0,
    this.reliefThickness = 6.0,
  });

  @override
  State<ReliefSectionButton> createState() => _ReliefSectionButtonState();
}

class _ReliefSectionButtonState extends State<ReliefSectionButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => _isPressed = false);
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        width: widget.size,
        height: widget.size + widget.reliefThickness,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.reliefColor,
                  borderRadius: BorderRadius.circular(36.0),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              width: widget.size,
              height: widget.size,
              transform: Matrix4.translationValues(
                0,
                _isPressed ? widget.reliefThickness : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: widget.baseColor,
                borderRadius: BorderRadius.circular(36.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    offset: const Offset(-1, -1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.svgAsset,
                  width: 24.0,
                  height: 24.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
