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
  // --- INICIO: TAREAS DE INICIALIZACIÓN MÍNIMAS ---

  // 1. Asegura la inicialización de Flutter
  // Esto es lo ÚNICO que main debe 'await' (implícitamente)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configuración de UI MÍNIMA (opcional, si no necesita await)
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // (Movido a bootstrapProvider para asegurar que se ejecute después de los servicios)

  // --- FIN: TAREAS MÍNIMAS ---

  // Ejecuta la app (¡casi al instante!)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}