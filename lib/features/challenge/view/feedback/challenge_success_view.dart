// lib/features/challenge/view/feedback/challenge_success_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/core/providers/app_provider.dart';

// 🎉 Imports para verificación de lenguaje
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

class ChallengeSuccessView extends ConsumerWidget {
  final int trofeosObtenidos;

  const ChallengeSuccessView({super.key, required this.trofeosObtenidos});

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
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;
    final textTheme = challengeTheme.textTheme;

    return PopScope(
      canPop: false,
      child: Theme(
        data: challengeTheme,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  SizedBox(
                    height: 250,
                    child: Lottie.asset(
                      'assets/animations/fox_run.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '¡Eres todo un programador!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                      // 1. Actualizar estadísticas
                      ref.read(appBarProvider.notifier).fetchStats();
                      ref.read(oldStatsValuesProvider.notifier).state = null;
                      ref.read(shouldRefreshStatsProvider.notifier).state = false;

                      if (!context.mounted) return;

                      // 2. Preparar navegación
                      final returnPath = ref.read(navigationReturnPathProvider);
                      ref.read(navigationReturnPathProvider.notifier).state = '/home';

                      // 3. 🚀 OPTIMIZADO: Navegar INMEDIATAMENTE al home
                      context.go(returnPath);

                      // 4. 🎉 Verificar lenguaje en background (NO BLOQUEANTE)
                      final userId = ref.read(authStateProvider).value?.session?.user.id;
                      
                      if (userId != null) {
                        // Delay para que la navegación termine primero
                        Future.delayed(const Duration(milliseconds: 500), () async {
                          try {
                            await ref.read(languageCompletionProvider.notifier)
                                .checkLanguageCompletion(userId);
                            
                            if (!context.mounted) return;
                            
                            final languageState = ref.read(languageCompletionProvider);
                            
                            // Si completó Y tiene más de 1 lenguaje
                            if (languageState.isLanguageCompleted && 
                                languageState.unlockedLanguages.length > 1) {
                              
                              // Navegar a celebración desde el home
                              context.push('/language-completion', extra: {
                                'completedLanguage': languageState.currentLanguage,
                                'unlockedLanguages': languageState.unlockedLanguages,
                              });
                            }
                          } catch (e) {
                            debugPrint('Error verificando lenguaje: $e');
                          }
                        });
                      }
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
          ),
        ),
      ),
    );
  }
}