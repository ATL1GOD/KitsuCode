import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/core/utils/app_colors.dart';

import 'package:kitsucode/features/onboarding/view/widgets/onboarding_profile.dart';
import 'package:kitsucode/features/onboarding/view/widgets/onboarding_challenge.dart';
import 'package:kitsucode/features/onboarding/view/widgets/onboarding_result.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  // UI Helpers
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  // Profile State
  int? _selectedLanguageId;
  String? _selectedLanguageName;
  List<Map<String, dynamic>> _languages = [];

  // Game/Test State
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _onboardingChallenges = [];
  int _currentChallengeIndex = 0;
  int _totalScore = 0;
  bool _isProfileStep = true;
  bool _isLoading = false;
  bool _showResults = false; // <--- AGREGA ESTO

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _loadOnboardingChallenges();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- CARGA DE DATOS ---
  Future<void> _loadLanguages() async {
    try {
      final langs = await ref
          .read(profileRepositoryProvider)
          .getAvailableLanguages();
      if (mounted) setState(() => _languages = langs);
    } catch (e) {
      debugPrint("Error loading languages: $e");
    }
  }

  Future<void> _loadOnboardingChallenges() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_onboarding_retos',
      );
      if (response is List) {
        setState(() {
          _onboardingChallenges = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error loading onboarding challenges: $e");
    }
  }

  // --- LOGICA DEL NEGOCIO ---
  ColorScheme _getDynamicColorScheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (_selectedLanguageName == null) return Theme.of(context).colorScheme;

    final name = _selectedLanguageName!.toLowerCase();

    if (name.contains('python')) {
      final baseScheme = isDark
          ? pythonDarkColorScheme
          : pythonLightColorScheme;
      return baseScheme.copyWith(
        primary: baseScheme.secondary,
        onPrimary: baseScheme.onSecondary,
        primaryContainer: baseScheme.secondaryContainer,
        onPrimaryContainer: baseScheme.onSecondaryContainer,
      );
    } else if (name.contains('java')) {
      final baseScheme = isDark ? javaDarkColorScheme : javaLightColorScheme;
      return baseScheme.copyWith(
        primary: baseScheme.secondary,
        onPrimary: baseScheme.onSecondary,
        primaryContainer: baseScheme.secondaryContainer,
        onPrimaryContainer: baseScheme.onSecondaryContainer,
      );
    } else if (name.contains('c')) {
      return isDark ? cDarkColorScheme : cLightColorScheme;
    }

    return Theme.of(context).colorScheme;
  }

  void _startTest() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Elige un lenguaje para tu aventura!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_onboardingChallenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando test... espera un momento.')),
      );
      _loadOnboardingChallenges();
      return;
    }

    setState(() => _isProfileStep = false);
  }

  void _onChallengeFinished(bool isCorrect) {
    if (isCorrect) _totalScore += 10;

    if (_currentChallengeIndex < _onboardingChallenges.length - 1) {
      setState(() => _currentChallengeIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId == null) return;

      int nivel = 1;
      if (_totalScore > 30) nivel = 2;
      if (_totalScore > 70) nivel = 3;

      // 1. Guardar en Supabase (Se mantiene igual)
      await Supabase.instance.client.rpc(
        'completar_onboarding_final',
        params: {
          'p_user_id': userId,
          'p_nombre_perfil': _usernameController.text.trim(),
          'p_id_lenguaje': _selectedLanguageId,
          'p_nivel_conocimiento': nivel,
        },
      );

      // 2. Refrescar providers (Se mantiene igual)
      ref.invalidate(appBarProvider);
      ref.invalidate(userProfileByIdProvider(userId));

      // 3. EN LUGAR DE IR AL HOME, MOSTRAR RESULTADOS
      if (mounted) {
        setState(() {
          _isLoading = false; // Dejamos de cargar
          _showResults = true; // Mostramos la pantalla de resultados
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeColorScheme = _getDynamicColorScheme(context);
    return AnimatedTheme(
      data: Theme.of(context).copyWith(
        colorScheme: activeColorScheme,
        primaryColor: activeColorScheme.primary,
        scaffoldBackgroundColor:
            activeColorScheme.surface, // Importante para el fondo
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColorScheme.primary,
            foregroundColor: activeColorScheme.onPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: activeColorScheme.primary),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Builder(
        // Usamos Builder para que el contexto tenga el nuevo Theme
        builder: (innerContext) {
          // --- MOSTRAR RESULTADOS ---
          if (_showResults) {
            return OnboardingResultsView(
              score: _totalScore,
              username: _usernameController.text,
              languageName: _selectedLanguageName ?? 'Desconocido',
              onContinue: () {
                context.go('/home');
              },
            );
          }
          // PASO 1: PERFIL
          if (_isProfileStep) {
            final activeColorScheme = _getDynamicColorScheme(context);

            return AnimatedTheme(
              data: Theme.of(context).copyWith(
                colorScheme: activeColorScheme,
                primaryColor: activeColorScheme.primary,
                progressIndicatorTheme: ProgressIndicatorThemeData(
                  color: activeColorScheme.primary,
                ),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Scaffold(
                backgroundColor: activeColorScheme.surface,
                body: OnboardingProfileStep(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  languages: _languages,
                  selectedLanguageId: _selectedLanguageId,
                  colorScheme: activeColorScheme,
                  onLanguageSelected: (id, name) {
                    setState(() {
                      if (_selectedLanguageId == id) {
                        _selectedLanguageId = null;
                        _selectedLanguageName = null;
                      } else {
                        _selectedLanguageId = id;
                        _selectedLanguageName = name;
                      }
                    });
                  },
                  onStartTest: _startTest,
                ),
              ),
            );
          }

          // PASO 2: JUEGOS
          if (_onboardingChallenges.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final currentData = _onboardingChallenges[_currentChallengeIndex];

          return Scaffold(
            body: MediaQuery.removePadding(
              context: context,
              removeTop: true, // <--- ESTO ELIMINA EL ESPACIO SUPERIOR
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingGameRenderer(
                    tipoReto: currentData['tipo_reto'] as int,
                    content: currentData['contenido'],
                    onFinished: _onChallengeFinished,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
