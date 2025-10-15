import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Clase para contener los datos de cada sección
class SectionData {
  final Color color;
  final Color colorOscuro;
  final int etapa;
  final int seccion;
  final String titulo;

  const SectionData({
    required this.color,
    required this.colorOscuro,
    required this.etapa,
    required this.seccion,
    required this.titulo,
  });
}

// El Widget que construye la ruta o camino
class Section extends StatelessWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título de la sección con divisores
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
            const SizedBox(width: 16),
            Text(
              data.titulo,
              style: const TextStyle(
                color: Color(0xFF52656D),
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
          ],
        ),
        const SizedBox(height: 24.0),
        // Genera los 9 elementos de la sección (8 botones y 1 cofre)
        ...List.generate(
          9,
          (i) => i % 9 != 4
              ? Container(
                  margin: EdgeInsets.only(
                    bottom: i != 8 ? 24.0 : 0,
                    left: getLeft(i), // Margen izquierdo para el efecto zig-zag
                    right: getRight(i), // Margen derecho para el efecto zig-zag
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: data.colorOscuro, width: 6.0),
                    ),
                    borderRadius: BorderRadius.circular(36.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Acción al presionar el botón
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.color,
                      fixedSize: const Size(56, 48),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                    child: SvgPicture.asset(
                      'assets/estrella.svg', // Icono del botón
                      width: 24.0,
                      height: 24.0,
                    ),
                  ),
                )
              : Container(
                  // Elemento del cofre en el centro
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: SvgPicture.asset(
                    'assets/cofre-ruta.svg',
                    width: 72,
                    height: 72,
                  ),
                ),
        ),
      ],
    );
  }

  // Calcula el margen izquierdo basado en el índice del elemento
  double getLeft(int indice) {
    const margin = 72.0;
    int pos = indice % 9;

    if (pos == 1) {
      return margin;
    }
    if (pos == 2) {
      return margin * 2;
    }
    if (pos == 3) {
      return margin;
    }

    return 0.0;
  }

  // Calcula el margen derecho basado en el índice del elemento
  double getRight(int indice) {
    const margin = 72.0;
    int pos = indice % 9;

    if (pos == 5) {
      return margin;
    }
    if (pos == 6) {
      return margin * 2;
    }
    if (pos == 7) {
      return margin;
    }

    return 0.0;
  }
}
