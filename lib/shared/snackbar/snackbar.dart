import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

/// Muestra un AwesomeSnackbar personalizado.
///
/// Esta es la función principal que encapsula toda la lógica
/// para mostrar tu snackbar con el estilo de KitsuCode.
void showAwesomeSnackbar(
  BuildContext context,
  String title,
  String message,
  ContentType contentType,
) {
  // Oculta cualquier snackbar que esté activo para evitar que se apilen
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // Crea el SnackBar
  final snackBar = SnackBar(
    /// El contenido es tu widget de AwesomeSnackbar
    content: AwesomeSnackbarContent(
      title: title,
      message: message,
      contentType: contentType,

      // Opcional: Puedes personalizar los colores aquí si quieres
      // color: Colors.blue, // Reemplaza el color por defecto
    ),

    // --- ESTAS PROPIEDADES SON CLAVE ---
    backgroundColor: Colors.transparent, // Fondo transparente
    elevation: 0, // Sin sombra
    behavior: SnackBarBehavior.floating, // Flotante
    // --- FIN PROPIEDADES CLAVE ---

    // Opcional: Define una duración estándar
    duration: const Duration(seconds: 3),
  );

  // Muestra el SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// --- ¡BONUS! ---
// Para hacerlo AÚN MÁS FÁCIL, puedes crear funciones "helper"
// para no tener que recordar el ContentType cada vez.

void showSuccessSnackbar(BuildContext context, String title, String message) {
  showAwesomeSnackbar(context, title, message, ContentType.success);
}

void showErrorSnackbar(BuildContext context, String title, String message) {
  showAwesomeSnackbar(context, title, message, ContentType.failure);
}

void showWarningSnackbar(BuildContext context, String title, String message) {
  showAwesomeSnackbar(context, title, message, ContentType.warning);
}

void showHelpSnackbar(BuildContext context, String title, String message) {
  showAwesomeSnackbar(context, title, message, ContentType.help);
}
