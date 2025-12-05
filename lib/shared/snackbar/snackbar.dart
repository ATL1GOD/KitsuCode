//ruta: lib/shared/snackbar/snackbar.dart
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

/// Muestra un AwesomeSnackbar personalizado.
void showAwesomeSnackbar(
  BuildContext context,
  String title,
  String message,
  ContentType contentType,
) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  final snackBar = SnackBar(
    content: AwesomeSnackbarContent(
      title: title,
      message: message,
      contentType: contentType,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
    margin: const EdgeInsets.only(
      bottom: 20,
      left: 10,
      right: 10,
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

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
