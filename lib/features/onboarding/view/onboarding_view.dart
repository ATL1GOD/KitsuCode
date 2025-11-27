import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTS DE TUS JUEGOS Y MODELOS
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
  // --- VARIABLES DEL PERFIL (PASO 1) ---
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  int? _selectedLanguageId;
  // _selectedLanguageName eliminado ya que no se usaba para lógica, solo UI local
  List<Map<String, dynamic>> _languages = [];
  final String mobileLogoPath = 'assets/images/auth/fox_login.webp';

  // --- VARIABLES DEL TEST (PASO 2) ---
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

  Future<void> _loadLanguages() async {
    try {
      final langs = await ref.read(profileRepositoryProvider).getAvailableLanguages();
      if (mounted) setState(() => _languages = langs);
    } catch (e) {
      debugPrint("Error loading languages: $e");
    }
  }

  Future<void> _loadOnboardingChallenges() async {
    try {
      final response = await Supabase.instance.client.rpc('get_onboarding_retos');
      if (response is List) {
        setState(() {
          _onboardingChallenges = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error loading onboarding challenges: $e");
    }
  }

  void _startTest() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Elige un lenguaje para tu aventura!')),
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
      setState(() {
        _currentChallengeIndex++;
      });
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
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

      await Supabase.instance.client.rpc('completar_onboarding_final', params: {
        'p_user_id': userId,
        'p_nombre_perfil': _usernameController.text.trim(),
        'p_id_lenguaje': _selectedLanguageId,
        'p_nivel_conocimiento': nivel
      });

      ref.invalidate(appBarProvider);
      ref.invalidate(userProfileByIdProvider(userId));

      if (mounted) {
        String mensaje = "¡Bienvenido! Nivel detectado: ";
        if (nivel == 1) mensaje += "Aprendiz (Básico)";
        if (nivel == 2) mensaje += "Programador (Intermedio)";
        if (nivel == 3) mensaje += "Arquitecto (Avanzado)";
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isProfileStep) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildProfileForm(),
          ),
        ),
      );
    }

    if (_onboardingChallenges.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentData = _onboardingChallenges[_currentChallengeIndex];
    final tipoReto = currentData['tipo_reto'] as int;
    final contenido = currentData['contenido'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Test (${_currentChallengeIndex + 1}/${_onboardingChallenges.length})"),
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
        children: [
          _buildGameWidget(tipoReto, contenido)
        ],
      ),
    );
  }

  Widget _buildGameWidget(int tipo, dynamic jsonContent) {
    switch (tipo) {
      case 1: // PUZZLE
        WidgetsBinding.instance.addPostFrameCallback((_) {
            final model = PuzzleChallengeModel.fromJson(jsonContent);
            ref.read(puzzleProvider.notifier).loadChallengeFromModel(model); 
        });
        return PuzzleView(
          onOnboardingFinished: _onChallengeFinished,
        );

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
        // Ahora usamos .fromJson que definimos en el QuizData corregido
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

  Widget _buildProfileForm() {
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Image.asset(mobileLogoPath, height: 200),
          const SizedBox(height: 20),
          Text("Configura tu Perfil", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary)),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: "Nombre de Usuario",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (v) => (v == null || v.length < 3) ? "Mínimo 3 caracteres" : null,
          ),
          
          const SizedBox(height: 30),
          const Text("Elige tu lenguaje base:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _languages.map((l) {
              final isSelected = _selectedLanguageId == l['id_lenguaje'];
              return ChoiceChip(
                label: Text(l['nombre']),
                selected: isSelected,
                selectedColor: colors.primaryContainer,
                onSelected: (sel) {
                  setState(() {
                    _selectedLanguageId = l['id_lenguaje'];
                    // _selectedLanguageName = l['nombre']; // Opcional si no lo usas
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _startTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: const Text("COMENZAR EVALUACIÓN"),
            ),
          ),
        ],
      ),
    );
  }
}