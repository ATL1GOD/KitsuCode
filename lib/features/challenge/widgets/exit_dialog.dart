// lib/shared/widgets/show_app_exit_dialog.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:giffy_dialog/giffy_dialog.dart';

/// Muestra un diálogo de confirmación genérico para salir de un reto.
void showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // (Este es tu mismo código de GiffyDialog)
      return GiffyDialog.image(
        Image.asset(
          "images/challenge/alerta1.png",
          height: 280,
          fit: BoxFit.cover,
        ),
        title: const Text(
          '¿Quieres salir del reto?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tu progreso en este reto se perderá.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () => Navigator.pop(context), // Cierra el diálogo
            child: const Text('CANCELAR'),
          ),
          const SizedBox(width: 98),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
