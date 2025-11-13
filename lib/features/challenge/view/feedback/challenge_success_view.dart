// lib/features/challenge/view/feedback/challenge_success_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- FUSIÓN: Se mantiene TU import de navigation_tracker_provider ---
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:lottie/lottie.dart'; // Necesitarás Lottie para la animación
import 'package:kitsucode/core/providers/app_provider.dart';

class ChallengeSuccessView extends ConsumerWidget {
  final int trofeosObtenidos;

  const ChallengeSuccessView({super.key, required this.trofeosObtenidos});

  // --- Función helper para obtener el Tema ---
  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (langName.toLowerCase().trim()) {
      case 'python':
        return isDark ? AppThemes.pythonDarkTheme : AppThemes.pythonTheme;
      case 'c':
        return isDark ? AppThemes.cDarkTheme : AppThemes.cTheme;
      case 'java':
        return isDark ? AppThemes.javaDarkTheme : AppThemes.javaTheme;
      default:
        // Fallback al tema principal
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtenemos el tema del lenguaje actual
    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;
    final textTheme = challengeTheme.textTheme;

    // 2. Envolvemos el Scaffold en el Tema del lenguaje
    return PopScope(
      canPop: false, // Bloquear el botón de retroceso y el gesto de swipe back
      child: Theme(
        data: challengeTheme,
        child: Scaffold(
          backgroundColor: colorScheme.surface, // Fondo con el color del tema
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // --- Animación o Ilustración ---
                  SizedBox(
                    height: 250,
                    child: Lottie.asset(
                      'assets/animations/fox_run.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Mensaje de Felicitación ---
                  Text(
                    '¡Eres todo un programador!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          colorScheme.primary, // Color principal del lenguaje
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Trofeos Ganados ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: colorScheme.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '+$trofeosObtenidos Trofeos',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // --- Botón de Continuar ---
                  // --- FUSIÓN: Se usa TU 'onPressed' (dxniel7) ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      ref.read(appBarProvider.notifier).fetchStats();

                      // El resto de tu lógica se queda igual
                      ref.read(oldStatsValuesProvider.notifier).state = null;
                      ref.read(shouldRefreshStatsProvider.notifier).state = false;

                      if (!context.mounted) return;

                      final returnPath = ref.read(navigationReturnPathProvider);
                      ref.read(navigationReturnPathProvider.notifier).state = '/home';
                      context.go(returnPath);
                    },
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // Cierra SafeArea
        ), // Cierra Scaffold
      ), // Cierra Theme
    ); // Cierra PopScope
  }
}
