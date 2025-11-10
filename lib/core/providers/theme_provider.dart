import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

// Este provider lee el string 'light', 'dark', o 'system' de settingsProvider
// y lo convierte en un ThemeMode real de Flutter.
final themeModeProvider = Provider<ThemeMode>((ref) {

  // Observa el estado de las preferencias del usuario
  final settingsState = ref.watch(settingsProvider);

  // Mientras carga o si hay error, usa el tema del sistema
  if (settingsState.isLoading || settingsState.hasError) {
    return ThemeMode.system;
  }

  // Cuando tiene datos, usa el valor de la BD
  final themeString = settingsState.value!.temaVisual;

  switch (themeString) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
});