import 'package:flutter/material.dart';

abstract class Breakpoints {
  /// Max width for a small layout.
  static const double small = 576;

  /// Max width for a medium layout.
  static const double medium = 900;

  /// Max width for a large layout.
  static const double large = 1100;
}

class ResponsiveLayout extends StatelessWidget {
  /// El widget que se mostrará en pantallas pequeñas (móviles).
  final Widget smallScaffold;

  /// El widget que se mostrará en pantallas medianas (tablets).
  /// Si es nulo, se usará [largeScaffold] en su lugar.
  final Widget? mediumScaffold;

  /// El widget que se mostrará en pantallas grandes (escritorio).
  final Widget largeScaffold;

  const ResponsiveLayout({
    super.key,
    required this.smallScaffold,
    this.mediumScaffold,
    required this.largeScaffold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Lógica basada en los archivos que proporcionaste:
        // 1. Si el ancho es menor o igual al breakpoint 'pequeño'.
        if (maxWidth <= Breakpoints.small) {
          return smallScaffold;
        }
        // 2. Si el ancho es menor o igual al breakpoint 'mediano'.
        else if (maxWidth <= Breakpoints.medium) {
          // Mantenemos tu lógica original: si no hay layout mediano, muestra el grande.
          return mediumScaffold ?? largeScaffold;
        }
        // 3. Para cualquier otro caso (mayor al mediano).
        else {
          return largeScaffold;
        }
      },
    );
  }
}
