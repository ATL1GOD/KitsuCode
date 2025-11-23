import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  int? _selectedLanguageId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _languages = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await ref
          .read(profileRepositoryProvider)
          .getAvailableLanguages();
      setState(() => _languages = langs);
    } catch (e) {
      // Manejar error de carga
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId == null) throw Exception("No user found");

      await ref
          .read(profileRepositoryProvider)
          .completeOnboarding(
            userId: userId,
            username: _usernameController.text.trim(),
            languageId: _selectedLanguageId!,
          );

      // IMPORTANTE: Invalidar el provider del perfil para que la app sepa
      // que ya completaste el onboarding y recargue los datos.
      ref.invalidate(userProfileByIdProvider(userId));

      if (mounted) {
        context.go('/'); // Ir al Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bienvenido a KitsuCode")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Elige tu nombre de usuario único:"),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: "Ej. KitsuMaster99",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty || val.length < 3
                    ? 'Mínimo 3 caracteres'
                    : null,
              ),
              const SizedBox(height: 30),
              const Text("¿Qué lenguaje quieres aprender?"),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguageId == lang['id_lenguaje'];
                  return ChoiceChip(
                    label: Text(lang['nombre']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLanguageId = selected
                            ? lang['id_lenguaje']
                            : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Comenzar Aventura"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
