// lib/shared/widgets/show_app_exit_dialog.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:giffy_dialog/giffy_dialog.dart';

/// Muestra un diálogo de confirmación genérico para salir de un reto.
void showExitDialog(BuildContext context) {
  // --- INICIO DE CAMBIOS ---

  // 1. OBTÉN EL TEMA
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  // 2. DEFINE ESTILOS DE TEXTO BASADOS EN EL TEMA
  // Usamos 'headlineSmall' para el título y 'bodyLarge' para el contenido.
  final titleStyle = textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
  );
  final contentStyle = textTheme.bodyLarge;
  // 'labelLarge' es el estilo estándar para texto de botones en Material 3
  final buttonTextStyle = textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.bold,
  );

  // --- FIN DE CAMBIOS ---

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return GiffyDialog.image(
        Image.asset(
          "images/challenge/alerta1.png",
          height: 280, // <-- Valor fijo original
          fit: BoxFit.cover,
        ),
        title: Text(
          '¿Quieres salir del reto?',
          textAlign: TextAlign.center,
          style: titleStyle, // <-- TEMA
        ),
        content: Text(
          'Tu progreso en este reto se perderá.',
          textAlign: TextAlign.center,
          style: contentStyle, // <-- TEMA
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              // Usa un color del tema (como 'onSurfaceVariant') para el texto
              foregroundColor: colorScheme.onSurfaceVariant, // <-- TEMA
              textStyle: buttonTextStyle, // <-- TEMA
            ),
            onPressed: () => Navigator.pop(context), // Cierra el diálogo
            child: const Text('CANCELAR'),
          ),
          const SizedBox(width: 98), // <-- Valor fijo original
          TextButton(
            style: TextButton.styleFrom(
              // Usa los colores de 'error' del tema.
              backgroundColor: colorScheme.error, // <-- TEMA
              foregroundColor: colorScheme.onError, // <-- TEMA
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ), // <-- Valor fijo original
              textStyle: buttonTextStyle, // <-- TEMA
            ),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              context.pop(); // Cierra la pantalla actual (p.ej. QuizPage)
            },
            child: const Text('SALIR'),
          ),
        ],
      );
    },
  );
}
