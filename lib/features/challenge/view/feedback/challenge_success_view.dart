// lib/features/challenge/view/feedback/challenge_success_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/core/providers/app_provider.dart';

//Imports para verificación de lenguaje
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeSuccessView extends ConsumerStatefulWidget {
  final int trofeosObtenidos;

  const ChallengeSuccessView({super.key, required this.trofeosObtenidos});

  @override
  ConsumerState<ChallengeSuccessView> createState() => _ChallengeSuccessViewState();
}

class _ChallengeSuccessViewState extends ConsumerState<ChallengeSuccessView> {
  bool _isNavigating = false;

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

  // inicio de metodo para manejar la navegacion despues del exito
  Future<void> _handleContinue() async {
    if (_isNavigating) return;
    
    setState(() => _isNavigating = true);

    try {
      // 1. Actualizar estadísticas
      ref.read(appBarProvider.notifier).fetchStats();
      ref.read(oldStatsValuesProvider.notifier).state = null;
      ref.read(shouldRefreshStatsProvider.notifier).state = false;

      // Obtener total de lenguajes en la app 
      final int totalLanguagesInApp = await Supabase.instance.client
          .rpc('get_total_languages_count');
      // Guardar en el provider

      // 2. Verificar si completó el lenguaje
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      bool shouldShowCelebration = false;
      String completedLanguage = '';
      List<String> unlockedLanguages = [];
      bool canUnlock = true;

      if (userId != null) {
        // Hacer la verificación
        await ref.read(languageCompletionProvider.notifier)
            .checkLanguageCompletion(userId);
        
        final languageState = ref.read(languageCompletionProvider);
        
        // Lógica para 1 solo lenguaje (esto está perfecto)
        shouldShowCelebration = languageState.hasCompletedLanguage && 
                                 languageState.canUnlockNewLanguage &&
                                 languageState.unlockedLanguages.length < totalLanguagesInApp;
        
        if (shouldShowCelebration) {
          completedLanguage = languageState.currentLanguage;
          unlockedLanguages = languageState.unlockedLanguages;
          canUnlock = languageState.canUnlockNewLanguage;
          
        } else if (languageState.hasCompletedLanguage && 
                   !languageState.canUnlockNewLanguage) {
          // Si completó pero ya no puede desbloquear (ya fue usado), ir al home
        
        } else if (languageState.hasCompletedLanguage && 
                   languageState.unlockedLanguages.length >= totalLanguagesInApp) {
          
          // solución para el caso de que complete TODOS los lenguajes
          
          // El 'languageState.currentLanguage' tiene el 3er lenguaje (ej. 'Python')
          final String lenguajeActual = languageState.currentLanguage;

          // ¿Este lenguaje 'canUnlockNewLanguage'?
          // Si es 'true', es la primera vez que completamos este 3er lenguaje.
          final bool esLaPrimeraVez = languageState.canUnlockNewLanguage;

          if (esLaPrimeraVez && lenguajeActual.isNotEmpty) {
            // ¡Es la primera vez!
            
            // 1. Marcamos el 3er lenguaje como "usado" en la BD
            try {
              final supabase = Supabase.instance.client;
              // Obtener array actual
              final userResponse = await supabase
                  .from('usuarios')
                  .select('lenguajes_usados_desbloqueo')
                  .eq('id', userId)
                  .single();

              final currentList = userResponse['lenguajes_usados_desbloqueo'] as List?;
              final usados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
              
              usados.add(lenguajeActual.trim().toLowerCase());
              
              await supabase
                  .from('usuarios')
                  .update({'lenguajes_usados_desbloqueo': usados.toList()})
                  .eq('id', userId);
              
            } catch (e) {
              // Silencioso en producción
            }

            // 2. Configuramos la navegación a la pantalla final
            shouldShowCelebration = true;
            completedLanguage = 'ALL';
            unlockedLanguages = languageState.unlockedLanguages;
            canUnlock = false; // No hay más lenguajes para desbloquear

          } else {
            // No es la primera vez (canUnlock es false porque ya lo marcamos)
            // No hacemos nada, 'shouldShowCelebration' queda 'false'
          }
          
          // fin de la solución
        }
      }

      if (!mounted) return;

      // 3. Decidir la navegación basado en el resultado
      if (shouldShowCelebration) {
        // Ir a la celebración (sea de 1 o de TODOS)
        context.go('/language-completion', extra: {
          'completedLanguage': completedLanguage,
          'unlockedLanguages': unlockedLanguages,
          'canUnlockNewLanguage': canUnlock,
        });
      } else {
        // Ir al home normalmente
        final returnPath = ref.read(navigationReturnPathProvider);
        ref.read(navigationReturnPathProvider.notifier).state = '/home';
        context.go(returnPath);
      }
    } catch (e) {
      if (mounted) {
        final returnPath = ref.read(navigationReturnPathProvider);
        ref.read(navigationReturnPathProvider.notifier).state = '/home';
        context.go(returnPath);
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }
  // fin de metodo 

  @override
  Widget build(BuildContext context) {
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
                          '+${widget.trofeosObtenidos} Trofeos',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botón con loading state
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: _isNavigating ? null : _handleContinue,
                    child: _isNavigating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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