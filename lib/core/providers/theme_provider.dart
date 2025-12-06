import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsState = ref.watch(settingsProvider);

  if (settingsState.isLoading || settingsState.hasError) {
    return ThemeMode.system;
  }

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
