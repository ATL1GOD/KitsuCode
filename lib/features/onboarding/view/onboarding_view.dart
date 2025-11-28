import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORTS DE UTILIDADES VISUALES (Asegúrate de que estas rutas sean correctas) ---
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';

// --- IMPORTS DE TUS JUEGOS Y MODELOS ---
import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

import 'package:kitsucode/features/columnas_game/view/columnas_view.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';

import 'package:kitsucode/features/codigo_game/view/codigo_view.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';

import 'package:kitsucode/features/quiz_game/view/widgets/quiz_view.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  // --- VARIABLES DE UI Y PERFIL (MEZCLA DE AMBOS ARCHIVOS) ---
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  int? _selectedLanguageId;
  String? _selectedLanguageName; // Necesario para la lógica de colores

  List<Map<String, dynamic>> _languages = [];

  // Rutas de imágenes
  final String mobileLogoPath = 'assets/images/auth/fox_login.webp';
  final String desktopHeroPath = 'assets/images/auth/fox_login.webp';

  // --- VARIABLES DEL TEST (LÓGICA ORIGINAL) ---
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _onboardingChallenges = [];
  int _currentChallengeIndex = 0;
  int _totalScore = 0;
  bool _isProfileStep = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _loadOnboardingChallenges();
  }

  // --- 1. LÓGICA DE CARGA ---

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

  // --- 2. LÓGICA DE COLORES DINÁMICOS (DEL FRONTEND MEJORADO) ---
  ColorScheme _getDynamicColorScheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (_selectedLanguageName == null) {
      return Theme.of(context).colorScheme;
    }

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

  // --- 3. LÓGICA DE NAVEGACIÓN (DEL ARCHIVO ORIGINAL) ---

  void _startTest() {
    // Validaciones
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

    // Si no cargaron los retos, reintentar
    if (_onboardingChallenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando test... espera un momento.')),
      );
      _loadOnboardingChallenges();
      return;
    }

    // CAMBIO DE FASE: De Perfil a Test
    setState(() => _isProfileStep = false);
  }

  void _onChallengeFinished(bool isCorrect) {
    if (isCorrect) _totalScore += 10;

    if (_currentChallengeIndex < _onboardingChallenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  int _calculateLevel() {
    if (_totalScore <= 30) return 1;
    if (_totalScore <= 70) return 2;
    return 3;
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId == null) return;

      final nivel = _calculateLevel();

      await Supabase.instance.client.rpc(
        'completar_onboarding_final',
        params: {
          'p_user_id': userId,
          'p_nombre_perfil': _usernameController.text.trim(),
          'p_id_lenguaje': _selectedLanguageId,
          'p_nivel_conocimiento': nivel,
        },
      );

      ref.invalidate(appBarProvider);
      ref.invalidate(userProfileByIdProvider(userId));

      if (mounted) {
        String mensaje = "¡Bienvenido! Nivel detectado: ";
        if (nivel == 1) mensaje += "Aprendiz (Básico)";
        if (nivel == 2) mensaje += "Programador (Intermedio)";
        if (nivel == 3) mensaje += "Arquitecto (Avanzado)";

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje)));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // AQUI ES DONDE OCURRE LA MAGIA DE FUSIÓN
    // Si estamos en el paso de perfil, mostramos el diseño MEJORADO
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
          // Usamos el ResponsiveLayout del archivo mejorado
          body: ResponsiveLayout(
            smallScaffold: _buildMobileLayout(activeColorScheme),
            largeScaffold: _buildDesktopLayout(activeColorScheme),
          ),
        ),
      );
    }

    // Si NO es el paso de perfil (es decir, son los retos), usamos el diseño ORIGINAL
    if (_onboardingChallenges.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentData = _onboardingChallenges[_currentChallengeIndex];
    final tipoReto = currentData['tipo_reto'] as int;
    final contenido = currentData['contenido'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Test (${_currentChallengeIndex + 1}/${_onboardingChallenges.length})",
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentChallengeIndex + 1) / _onboardingChallenges.length,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildGameWidget(tipoReto, contenido)],
      ),
    );
  }

  // --- 5. WIDGETS DE JUEGO (LÓGICA ORIGINAL) ---

  Widget _buildGameWidget(int tipo, dynamic jsonContent) {
    switch (tipo) {
      case 1: // PUZZLE
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final model = PuzzleChallengeModel.fromJson(jsonContent);
          ref.read(puzzleProvider.notifier).loadChallengeFromModel(model);
        });
        return PuzzleView(onOnboardingFinished: _onChallengeFinished);

      case 2: // RELACIÓN
        final model = ColumnsChallenge.fromJson(jsonContent);
        return ColumnsChallengeView(
          challenge: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: _onChallengeFinished,
        );

      case 3: // CÓDIGO
        final model = CodigoChallenge.fromJson(jsonContent);
        return CodigoChallengeView(
          challenge: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: _onChallengeFinished,
        );

      case 4: // QUIZ
        final model = QuizData.fromJson(jsonContent);
        return QuizPage(
          mydata: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: _onChallengeFinished,
        );

      default:
        return Center(child: Text("Tipo de reto desconocido: $tipo"));
    }
  }

  // --- 6. WIDGETS VISUALES DEL PERFIL (DEL FRONTEND MEJORADO) ---

  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildFormContent(colorScheme, isCompact: true),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              image: DecorationImage(
                image: AssetImage(desktopHeroPath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary.withOpacity(0.85),
                  BlendMode.srcOver,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "KitsuCode",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Tu camino ninja en la programación comienza aquí.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 40,
                ),
                child: _buildFormContent(colorScheme, isCompact: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(ColorScheme colorScheme, {required bool isCompact}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCompact) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Image.asset(
                mobileLogoPath,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              "¡Bienvenido a KitsuCode!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Configura tu perfil para comenzar",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
          ] else ...[
            Text(
              "Crea tu Perfil",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              "Completa tus datos para acceder al dojo.",
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
          ],

          Text(
            "Elige tu nombre de usuario",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Ej. KitsuCode_Pro",
              prefixIcon: Icon(Icons.person_pin, color: colorScheme.primary),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Requerido';
              if (val.length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ),

          const SizedBox(height: 30),

          Text(
            "Elige tu lenguaje de programación favorito",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 15),

          _languages.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: isCompact
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  children: _languages.map((lang) {
                    final isSelected =
                        _selectedLanguageId == lang['id_lenguaje'];
                    return _buildTechChip(
                      label: lang['nombre'],
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedLanguageId = null;
                            _selectedLanguageName = null;
                          } else {
                            _selectedLanguageId = lang['id_lenguaje'];
                            _selectedLanguageName = lang['nombre'];
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

          const SizedBox(height: 50),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            // IMPORTANTE: Aquí cambiamos el onPressed para que llame a _startTest
            // en lugar de enviar los datos al backend directamente.
            child: ElevatedButton(
              onPressed: _startTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "COMENZAR AVENTURA",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 18, color: colorScheme.onPrimary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
