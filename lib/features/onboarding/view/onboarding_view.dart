import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_colors.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';
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
  String? _selectedLanguageName;
  bool _isLoading = false;
  List<Map<String, dynamic>> _languages = [];

  // --- RUTAS DE TUS IMÁGENES ---
  final String mobileLogoPath = 'assets/images/auth/fox_login.webp';
  final String desktopHeroPath = 'assets/images/auth/fox_login.webp';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  // --- LÓGICA DE COLORES AJUSTADA ---
  ColorScheme _getDynamicColorScheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // 1. Si no hay nada seleccionado, usa el tema default
    if (_selectedLanguageName == null) {
      return Theme.of(context).colorScheme;
    }

    final name = _selectedLanguageName!.toLowerCase();

    // 2. Lógica para Python (Tono Amarillo)
    if (name.contains('python')) {
      // Obtenemos el esquema base de Python (que es azulado/teal)
      final baseScheme = isDark
          ? pythonDarkColorScheme
          : pythonLightColorScheme;

      // TRUCO: Intercambiamos el Primary por el Secondary (que es el amarillo 0xFFFEB716)
      // para que los botones y bordes activos se vean amarillos.
      return baseScheme.copyWith(
        primary: baseScheme.secondary,
        onPrimary: baseScheme
            .onSecondary, // Asegura que el texto sobre el botón sea legible (negro)
        primaryContainer: baseScheme.secondaryContainer,
        onPrimaryContainer: baseScheme.onSecondaryContainer,
      );
    }
    // 3. Lógica para Java (Tono Rojizo)
    else if (name.contains('java')) {
      // Obtenemos el esquema base de Java (que es azul oscuro)
      final baseScheme = isDark ? javaDarkColorScheme : javaLightColorScheme;

      // TRUCO: Intercambiamos el Primary por el Secondary (que es rojizo/naranja 0xFFF86541)
      return baseScheme.copyWith(
        primary: baseScheme.secondary,
        onPrimary: baseScheme.onSecondary,
        primaryContainer: baseScheme.secondaryContainer,
        onPrimaryContainer: baseScheme.onSecondaryContainer,
      );
    }
    // 4. Lógica para C (Tono Azul - Se queda igual)
    else if (name.contains('c')) {
      return isDark ? cDarkColorScheme : cLightColorScheme;
    }

    return Theme.of(context).colorScheme;
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await ref
          .read(profileRepositoryProvider)
          .getAvailableLanguages();
      setState(() => _languages = langs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando lenguajes: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Elige un lenguaje para tu aventura!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId == null) throw Exception("No se encontró usuario autenticado");

      await ref
          .read(profileRepositoryProvider)
          .completeOnboarding(
            userId: userId,
            username: _usernameController.text.trim(),
            languageId: _selectedLanguageId!,
          );

      ref.invalidate(userProfileByIdProvider(userId));
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ocurrió un error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColorScheme = _getDynamicColorScheme(context);

    return AnimatedTheme(
      data: Theme.of(context).copyWith(
        colorScheme: activeColorScheme,
        primaryColor: activeColorScheme.primary,
        // Ajustamos el color del indicador de carga para que coincida con el nuevo primario
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: activeColorScheme.primary,
        ),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Scaffold(
        backgroundColor: activeColorScheme.surface,
        body: ResponsiveLayout(
          smallScaffold: _buildMobileLayout(activeColorScheme),
          largeScaffold: _buildDesktopLayout(activeColorScheme),
        ),
      ),
    );
  }

  // --- LAYOUT MOVIL ---
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

  // --- LAYOUT ESCRITORIO ---
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
                // Filtro de color dinámico sobre la imagen
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
                    // Usamos onPrimary si el fondo es primary, o onPrimaryContainer si es container.
                    // Al usar el filtro srcOver con Primary, el texto debe ser onPrimary (usualmente blanco o negro)
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

  // --- CONTENIDO DEL FORMULARIO ---
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
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2.5,
                    )
                  : const Row(
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
              ? colorScheme
                    .primary // Usamos primary directamente para el fondo seleccionado
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
              // Cambiamos el color del icono dependiendo del contraste (onPrimary)
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
