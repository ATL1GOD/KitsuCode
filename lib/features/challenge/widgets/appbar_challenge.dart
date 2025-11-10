import 'package:flutter/material.dart';

/// Un AppBar reutilizable para las dinámicas de retos.
///
/// Muestra un botón para cerrar (X) y una barra de progreso lineal.
/// NO incluye el temporizador del quiz.
class ChallengeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// El progreso actual a mostrar en la barra (valor entre 0.0 y 1.0).
  final double progress;

  /// El callback que se ejecuta al presionar el botón de cerrar (X).
  final VoidCallback? onClose;

  const ChallengeAppBar({super.key, required this.progress, this.onClose});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tema del contexto actual
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,

      // Botón de Cerrar (X)
      leading: onClose != null
          ? IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              onPressed: onClose, // Usamos el callback que nos pasaron
            )
          : null, // Si no hay callback, no se muestra el botón
      // Título (La barra de progreso)
      title: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: LinearProgressIndicator(
                value: progress, // Usamos el parámetro 'progress'
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 12,
              ),
            ),
          ),
          // --- ¡ELIMINADO! ---
          // Aquí es donde estaba el 'SizedBox(width: 10)' y el 'Container'
          // que dibujaba el cronómetro. Los hemos quitado.
        ],
      ),

      // Nos aseguramos de que el título se alinee a la izquierda
      centerTitle: false,
    );
  }

  /// Esto es necesario para que el widget pueda ser usado como un AppBar.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
