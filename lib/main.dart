// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart'; // <-- Importa el handler

// Route observer global (esto se queda igual)
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// El handler de background ahora vive en bootstrap_provider.dart
// pero lo importamos para que main.dart lo "conozca".

void main() {
  // 1. Asegura la inicialización de Flutter
  // Esto es lo ÚNICO que main debe 'await' (implícitamente)
  WidgetsFlutterBinding.ensureInitialized();
  // Ejecuta la app (¡casi al instante!)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}