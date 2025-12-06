import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/core/providers/app_provider.dart';

import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart';

class ChallengeSuccessView extends ConsumerStatefulWidget {
  final int trofeosObtenidos;

  const ChallengeSuccessView({super.key, required this.trofeosObtenidos});

  @override
  ConsumerState<ChallengeSuccessView> createState() =>
      _ChallengeSuccessViewState();
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

  Future<void> _handleContinue() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      final currentLangId = ref.read(appBarProvider).languageId;

      final results = await Future.wait([
        Future.delayed(const Duration(milliseconds: 700)),
        Supabase.instance.client.rpc(
          'get_my_language_score',
          params: {'p_language_id': currentLangId},
        ),
        userId != null
            ? ref
                  .read(languageCompletionProvider.notifier)
                  .checkLanguageCompletion(userId)
            : Future.value(),
        Supabase.instance.client.rpc('get_total_languages_count'),
      ]);

      if (!mounted) return;

      final realTotalTrophies = (results[1] as num?)?.toInt() ?? 0;
      final totalLanguagesInApp = results[3] as int;
      final languageState = ref.read(languageCompletionProvider);

      bool shouldShowCelebration = false;
      String completedLanguage = '';
      List<String> unlockedLanguages = [];
      bool canUnlock = true;

      if (userId != null) {
        if (languageState.hasCompletedLanguage &&
            languageState.canUnlockNewLanguage &&
            languageState.unlockedLanguages.length < totalLanguagesInApp) {
          shouldShowCelebration = true;
          completedLanguage = languageState.currentLanguage;
          unlockedLanguages = languageState.unlockedLanguages;
          canUnlock = languageState.canUnlockNewLanguage;
        } else if (languageState.hasCompletedLanguage &&
            languageState.unlockedLanguages.length >= totalLanguagesInApp) {
          final bool esLaPrimeraVez = languageState.canUnlockNewLanguage;

          if (esLaPrimeraVez && languageState.currentLanguage.isNotEmpty) {
            shouldShowCelebration = true;
            completedLanguage = 'ALL';
            unlockedLanguages = languageState.unlockedLanguages;
            canUnlock = false;
            _markLanguageAsUsedBackground(
              userId,
              languageState.currentLanguage,
            );
          }
        }
      }

      if (!mounted) return;

      if (shouldShowCelebration) {
        ref.read(oldStatsValuesProvider.notifier).state = null;
        ref.read(shouldRefreshStatsProvider.notifier).state = true;

        resumeMusicAfterChallenge(ref);

        context.go(
          '/language-completion',
          extra: {
            'completedLanguage': completedLanguage,
            'unlockedLanguages': unlockedLanguages,
            'canUnlockNewLanguage': canUnlock,
          },
        );
      } else {
        final oldTrophies = (realTotalTrophies - widget.trofeosObtenidos)
            .clamp(0, 999999)
            .toInt();
        ref.read(shouldRefreshStatsProvider.notifier).state = false;

        final currentStats = ref.read(appBarProvider);
        ref
            .read(appBarProvider.notifier)
            .updateStatsDirectly(
              lives: currentStats.lives,
              trophies: oldTrophies,
              streak: currentStats.streak,
            );

        final returnPath = ref.read(navigationReturnPathProvider);
        ref.read(navigationReturnPathProvider.notifier).state = '/home';
        ref.read(oldStatsValuesProvider.notifier).state = null;

        resumeMusicAfterChallenge(ref);

        context.go(returnPath);

        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;

          ref.read(appBarProvider.notifier).fetchStats();

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              ref.read(shouldRefreshStatsProvider.notifier).state = true;
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        resumeMusicAfterChallenge(ref);

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

  void _markLanguageAsUsedBackground(String userId, String languageName) async {
    try {
      final supabase = Supabase.instance.client;
      final userResponse = await supabase
          .from('usuarios')
          .select('lenguajes_usados_desbloqueo')
          .eq('id', userId)
          .single();

      final currentList = List<String>.from(
        userResponse['lenguajes_usados_desbloqueo'] ?? [],
      );
      final normalized = languageName.trim().toLowerCase();

      if (!currentList.contains(normalized)) {
        currentList.add(normalized);
        await supabase
            .from('usuarios')
            .update({'lenguajes_usados_desbloqueo': currentList})
            .eq('id', userId);
      }
    } catch (_) {}
  }

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
                      color: colorScheme.primaryContainer.withAlpha(128),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
