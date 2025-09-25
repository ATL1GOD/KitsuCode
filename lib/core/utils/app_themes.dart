import 'package:flutter/material.dart';
import 'package:kitsucode/core/utils/app_colors.dart';

class AppThemes {
  //Tema principal de la app
  static final ThemeData lightTheme = ThemeData.from(
    colorScheme: primaryLightColorScheme,
    useMaterial3: true,
  );
  static final ThemeData darkTheme = ThemeData.from(
    colorScheme: primaryDarkColorScheme,
    useMaterial3: true,
  );

  //Tema de Python de la app
  static final ThemeData pythonTheme = ThemeData.from(
    colorScheme: pythonLightColorScheme,
    useMaterial3: true,
  );
  static final ThemeData pythonDarkTheme = ThemeData.from(
    colorScheme: pythonDarkColorScheme,
    useMaterial3: true,
  );

  //Tema de C de la app
  static final ThemeData cTheme = ThemeData.from(
    colorScheme: cLightColorScheme,
    useMaterial3: true,
  );
  static final ThemeData cDarkTheme = ThemeData.from(
    colorScheme: cDarkColorScheme,
    useMaterial3: true,
  );

  //Tema de Java de la app
  static final ThemeData javaTheme = ThemeData.from(
    colorScheme: javaLightColorScheme,
    useMaterial3: true,
  );
  static final ThemeData javaDarkTheme = ThemeData.from(
    colorScheme: javaDarkColorScheme,
    useMaterial3: true,
  );
}
