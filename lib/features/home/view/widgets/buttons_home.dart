import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Función para oscurecer el color (usada para el relieve)
Color _darkenColor(Color color, double factor) {
  return HSLColor.fromColor(color)
      .withLightness(
        (HSLColor.fromColor(color).lightness - factor).clamp(0.0, 1.0),
      )
      .toColor();
}

class ReliefSectionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color baseColor;
  final Color reliefColor;
  final String svgAsset;
  final double size;
  final double reliefThickness;

  // --- NUEVAS PROPIEDADES ---
  final bool isLocked;
  final Color lockColor;
  // --- FIN NUEVAS PROPIEDADES ---

  const ReliefSectionButton({
    super.key,
    required this.onPressed,
    required this.baseColor,
    required this.reliefColor,
    required this.svgAsset,
    this.size = 56.0,
    this.reliefThickness = 6.0,
    this.isLocked = false,
    this.lockColor = const Color(0xFF52656D),
  });

  @override
  State<ReliefSectionButton> createState() => _ReliefSectionButtonState();
}

class _ReliefSectionButtonState extends State<ReliefSectionButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLocked) {
      // Solo si no está bloqueado
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    // Llamamos a onPressed siempre, para que el widget padre (map_home)
    // pueda manejar el SnackBar de "Bloqueado" si es necesario.
    widget.onPressed();

    if (!widget.isLocked) {
      // Solo si no está bloqueado
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted) setState(() => _isPressed = false);
      });
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // --- Determinar colores dinámicos ---
    final Color currentBaseColor = widget.isLocked
        ? widget.lockColor
        : widget.baseColor;
    final Color currentReliefColor = widget.isLocked
        ? _darkenColor(widget.lockColor, 0.2)
        : widget.reliefColor;
    // --- Fin determinación de colores ---

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
                  color: currentReliefColor, // Usar color dinámico
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
                color: currentBaseColor, // Usar color dinámico
                borderRadius: BorderRadius.circular(36.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(153),
                    offset: const Offset(-1, -1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Center(
                // --- Mostrar candado si está bloqueado ---
                child: widget.isLocked
                    ? const Icon(Icons.lock, color: Colors.white70, size: 24.0)
                    : SvgPicture.asset(
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
