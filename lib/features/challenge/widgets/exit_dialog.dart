import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ¡Ya no necesitas 'package:giffy_dialog/giffy_dialog.dart'!
// Puedes ejecutar: flutter pub remove giffy_dialog

/// Muestra un diálogo de confirmación genérico para salir de un reto.
void showExitDialog(BuildContext context) {
  // 1. OBTÉN EL TEMA (Esto se mantiene igual)
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  // 2. DEFINE ESTILOS DE TEXTO (Esto se mantiene igual)
  final titleStyle = textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
  );
  final contentStyle = textTheme.bodyLarge;
  final buttonTextStyle = textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.bold,
  );

  // --- INICIO DE CAMBIOS ---

  showDialog(
    context: context,
    builder: (BuildContext context) {
      // 3. REEMPLAZA GiffyDialog CON AlertDialog
      return AlertDialog(
        // Usa el color de fondo de tu tema
        backgroundColor: colorScheme.surface,
        // Define bordes redondeados
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),

        // 4. TÍTULO (¡Ahora está arriba!)
        title: Text(
          '¿Quieres salir del reto?',
          textAlign: TextAlign.center,
          style: titleStyle,
        ),

        // 5. CONTENIDO
        // Usamos una Columna para poner la imagen y el texto debajo
        content: Column(
          mainAxisSize: MainAxisSize.min, // ¡Muy importante!
          children: [
            // Tu imagen
            Image.asset(
              "images/challenge/alerta4.png",
              height: 220, // Ajusta esta altura como veas necesario
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16), // Espacio entre imagen y texto
            // Tu texto de contenido
            Text(
              'Tu progreso en este reto se perderá.',
              textAlign: TextAlign.center,
              style: contentStyle,
            ),
          ],
        ),

        // 6. ACCIONES (Tus mismos botones)
        // Alinear los botones
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Botón CANCELAR
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              textStyle: buttonTextStyle,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),

          // ¡Ya no necesitas el 'SizedBox(width: 98)'!
          // 'actionsAlignment' ya los separa adecuadamente.
          // Si quieres más espacio, puedes usar un SizedBox(width: 20) o similar.
          SizedBox(width: 80),
          // Botón SALIR
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: buttonTextStyle,
            ),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              context.pop(); // Cierra la pantalla actual
            },
            child: const Text('SALIR'),
          ),
        ],
      );
    },
  );
  // --- FIN DE CAMBIOS ---
}
