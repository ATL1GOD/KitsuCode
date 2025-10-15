import 'package:flutter/material.dart';

class CircularReliefButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Color iconColor;
  final Color baseColor;
  final Color reliefColor; // Este color será el del borde inferior visible

  const CircularReliefButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 80.0,
    this.iconColor = const Color(0xFF4A4A4A),
    this.baseColor = const Color(0xFFC0C0C0), // Gris claro para la superficie
    this.reliefColor = const Color(
      0xFF707070,
    ), // Gris oscuro para el relieve/borde inferior
  });

  @override
  State<CircularReliefButton> createState() => _CircularReliefButtonState();
}

class _CircularReliefButtonState extends State<CircularReliefButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    // Retraso mínimo para que la animación de "onPressed" se vea antes de ejecutar la acción
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Este valor ahora controla qué tan "grueso" es el relieve y qué tan lejos se mueve el botón.
    final double reliefThickness = widget.size * 0.12;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        // El widget completo necesita ser un poco más alto para que el relieve se vea.
        width: widget.size,
        height: widget.size + reliefThickness,
        child: Stack(
          alignment: Alignment.topCenter, // Los hijos se alinearán desde arriba
          children: [
            // 1. EL RELIEVE (CAPA INFERIOR)
            // Esta capa es estática. Es la "base" del botón.
            // Está posicionada para que solo su parte inferior sea visible.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.reliefColor,
                ),
              ),
            ),

            // 2. LA SUPERFICIE DEL BOTÓN (CAPA SUPERIOR ANIMADA)
            // Esta es la parte visible que se mueve hacia abajo.
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              width: widget.size,
              height: widget.size,
              // La propiedad 'transform' es la clave de la animación.
              // Cuando se presiona, mueve el contenedor hacia abajo por el grosor del relieve.
              transform: Matrix4.translationValues(
                0,
                _isPressed ? reliefThickness : 0,
                0,
              ),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.baseColor,
                // Sombras sutiles para darle más volumen a la superficie.
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    offset: const Offset(-2, -2),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.5,
                  color: widget.iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
