import 'package:flutter/material.dart';
import 'package:kitsucode/core/utils/responsive_layout.dart';

class OnboardingProfileStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final List<Map<String, dynamic>> languages;
  final int? selectedLanguageId;
  final Function(int id, String name) onLanguageSelected;
  final VoidCallback onStartTest;
  final ColorScheme colorScheme;

  // Rutas de imágenes
  final String mobileLogoPath = 'assets/images/auth/fox_login.webp';
  final String desktopHeroPath = 'assets/images/auth/fox_login.webp';

  const OnboardingProfileStep({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.languages,
    required this.selectedLanguageId,
    required this.onLanguageSelected,
    required this.onStartTest,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      smallScaffold: _buildMobileLayout(),
      largeScaffold: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildFormContent(isCompact: true),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
                    "Tu camino en la programación comienza aquí.",
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
                child: _buildFormContent(isCompact: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent({required bool isCompact}) {
    return Form(
      key: formKey,
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
            controller: usernameController,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Coloca tu nombre de usuario",
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
            "Elige tu lenguaje de programación",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 15),
          languages.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: isCompact
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  children: languages.map((lang) {
                    final isSelected =
                        selectedLanguageId == lang['id_lenguaje'];
                    return _buildTechChip(
                      label: lang['nombre'],
                      isSelected: isSelected,
                      onTap: () => onLanguageSelected(
                        lang['id_lenguaje'],
                        lang['nombre'],
                      ),
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
              onPressed: onStartTest,
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
                    "COMENZAR TEST",
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
