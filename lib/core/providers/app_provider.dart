// lib/shared/providers/navigation_provider.dart (o donde prefieras)

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Almacena la ruta a la que se debe navegar después de completar
/// (o fallar) un reto.
///
/// Por defecto es '/home', pero se puede sobreescribir antes de
/// lanzar un reto desde una sección especial (como /desafiomensual).
final navigationReturnPathProvider = StateProvider<String>((ref) {
  // El valor por defecto siempre será '/home'
  return '/home';
});
