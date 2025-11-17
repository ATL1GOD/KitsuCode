// lib/features/challenge/view/language_selection_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart'; 

// Modelo para representar un lenguaje
class Language {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final Color darkColor;
  final String description;
  final bool isLocked;

  Language({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.darkColor,
    required this.description,
    this.isLocked = false,
  });
}

class LanguageSelectionView extends ConsumerStatefulWidget {
  final List<String> unlockedLanguages; // ["Python", "Java"] por ejemplo
  final String currentLanguage; // El que acaba de completar

  const LanguageSelectionView({
    super.key,
    required this.unlockedLanguages,
    required this.currentLanguage,
  });

  @override
  ConsumerState<LanguageSelectionView> createState() =>
      _LanguageSelectionViewState();
}

class _LanguageSelectionViewState
    extends ConsumerState<LanguageSelectionView> {
  String? _selectedLanguage;
  bool _isLoading = false;

  // Definición de todos los lenguajes disponibles
  late final List<Language> _allLanguages;

  // funcion helper para obtener el tema del lenguaje
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
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    
    // Normalizar los nombres de los lenguajes desbloqueados (completados)
    final normalizedUnlocked = widget.unlockedLanguages
        .map((l) => l.trim().toLowerCase())
        .toList();
    
    // Normalizar el lenguaje actual (el que acaba de completar)
    final currentLangNormalized = widget.currentLanguage.trim().toLowerCase();
    
    // LÓGICA CORRECTA:
    // - Los lenguajes COMPLETADOS están bloqueados (ya los terminaste)
    // - Los lenguajes NO completados están desbloqueados (puedes elegirlos)
    
    _allLanguages = [
      Language(
        name: 'C',
        displayName: 'C',
        icon: Icons.memory,
        color: const Color(0xFF00599C),
        darkColor: const Color(0xFF004578),
        description: normalizedUnlocked.contains('c') 
            ? 'Ya dominaste este lenguaje' 
            : 'El lenguaje de los sistemas',
        isLocked: normalizedUnlocked.contains('c'), // Bloqueado si ya lo completaste
      ),
      Language(
        name: 'Java',
        displayName: 'Java',
        icon: Icons.coffee,
        color: const Color(0xFFF89820),
        darkColor: const Color(0xFFD17B1A),
        description: normalizedUnlocked.contains('java')
            ? 'Ya dominaste este lenguaje'
            : 'Programación orientada a objetos',
        isLocked: normalizedUnlocked.contains('java'), // Bloqueado si ya lo completaste
      ),
      Language(
        name: 'Python',
        displayName: 'Python',
        icon: Icons.code,
        color: const Color(0xFF3776AB),
        darkColor: const Color(0xFF2D5F8D),
        description: normalizedUnlocked.contains('python')
            ? 'Ya dominaste este lenguaje'
            : 'Lenguaje versátil y fácil de aprender',
        isLocked: normalizedUnlocked.contains('python'), // Bloqueado si ya lo completaste
      ),
    ];
  }

  Future<void> _selectLanguage(Language language) async {
    if (language.isLocked || _isLoading) return;

    setState(() {
      _selectedLanguage = language.name;
      _isLoading = true;
    });

    try {
      // Obtener el userId
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      // Actualizar el lenguaje favorito en Supabase
      // Pasar el lenguaje anterior (el que completaste) para marcarlo como "usado"
      await ref.read(languageCompletionProvider.notifier).updateFavoriteLanguage(
        userId,
        language.name.toLowerCase(),
        previousLanguage: widget.currentLanguage, // 🆕 El lenguaje que completaste
      );

      // CRÍTICO: Volver a verificar lenguajes completados
      await ref.read(languageCompletionProvider.notifier)
          .checkLanguageCompletion(userId);

      // CRÍTICO: Resetear el estado de completitud
      ref.read(languageCompletionProvider.notifier).resetCompletionState();

      // NUEVO: Actualizar el appBarProvider para reflejar el cambio
      await ref.read(appBarProvider.notifier).fetchStats();

      if (mounted) {
        //Usando AwesomeSnackbar
        showSuccessSnackbar(
          context,
          '¡Éxito!',
          'Cambiado a ${language.displayName}',
        );

        // Pequeño delay para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));

        // Navegar al home
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) { 
      // Manejar error
      if (mounted) {
        showErrorSnackbar(
          context,
          '¡Oops! Hubo un error',
          e.toString(),
        );
        setState(() {
          _isLoading = false;
          _selectedLanguage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // cambios de tema basados en el lenguaje
    final size = MediaQuery.of(context).size;
    // El tema se basa en el lenguaje que se acaba de completar
    final challengeTheme = _getLanguageTheme(
      widget.currentLanguage,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, 
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration( 
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Column(
                    children: [
                      // Ícono de estrella (Naranja intencional para recompensa)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade700,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 48,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(delay: 200.ms)
                          .then()
                          .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withOpacity(0.5)),

                      const SizedBox(height: 24),

                      // Título
                      Text(
                        '¡Nuevo Lenguaje Disponible!',
                        style: textTheme.displaySmall?.copyWith( 
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface, 
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 300.ms)
                          .slideY(begin: -0.2, end: 0, delay: 300.ms),

                      const SizedBox(height: 12),

                      // Subtítulo
                      Text(
                        'Selecciona el próximo lenguaje que quieres dominar',
                        style: textTheme.bodyLarge?.copyWith( 
                          color: colorScheme.onSurfaceVariant, 
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 500.ms)
                          .slideY(begin: -0.1, end: 0, delay: 500.ms),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Lista de lenguajes
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allLanguages.length,
                      itemBuilder: (context, index) {
                        final language = _allLanguages[index];
                        final isSelected = _selectedLanguage == language.name;
                        final delay = (700 + (index * 150)).toDouble();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _LanguageCard(
                            language: language,
                            isSelected: isSelected,
                            isLoading: _isLoading && isSelected,
                            onTap: () => _selectLanguage(language), 
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: delay.ms)
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              delay: delay.ms,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    ),
                  ),

                  // Nota informativa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1), 
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade300, // OK
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Podrás cambiar entre lenguajes desbloqueados en cualquier momento',
                            style: textTheme.bodySmall?.copyWith( 
                              color: colorScheme.onSurfaceVariant, 
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 1200.ms)
                      .slideY(begin: 0.2, end: 0, delay: 1200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tema y estilos
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: language.isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Los colores del lenguaje (azul, naranja) son intencionales
          gradient: language.isLocked
              ? LinearGradient(
                  colors: [
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ],
                )
              : LinearGradient(
                  colors: [
                    language.color.withOpacity(isSelected ? 0.3 : 0.15),
                    language.darkColor.withOpacity(isSelected ? 0.3 : 0.15),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: language.isLocked
                ? Colors.grey.shade700
                : isSelected
                    ? language.color
                    : language.color.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: language.isLocked
              ? []
              : [
                  BoxShadow(
                    color: language.color
                        .withOpacity(isSelected ? 0.4 : 0.2),
                    blurRadius: isSelected ? 20 : 10,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Ícono del lenguaje (colores intencionales)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: language.isLocked
                        ? Colors.grey.shade700
                        : language.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: language.isLocked
                          ? Colors.grey.shade600
                          : language.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    language.icon,
                    size: 30,
                    color: language.isLocked
                        ? Colors.grey.shade500
                        : language.color,
                  ),
                ),

                const SizedBox(width: 16),

                // Información del lenguaje
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            language.displayName,
                            style: textTheme.headlineSmall?.copyWith( 
                              fontWeight: FontWeight.bold,
                              color: language.isLocked
                                  ? Colors.grey.shade500
                                  : colorScheme.onSurface, 
                            ),
                          ),
                          if (language.isLocked) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green.shade400, 
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language.description,
                        style: textTheme.bodyMedium?.copyWith( 
                          color: language.isLocked
                              ? Colors.grey.shade600
                              : colorScheme.onSurfaceVariant, 
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de selección o loading (colores intencionales)
                if (!language.isLocked)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: isLoading
                        ? CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(language.color),
                          )
                        : isSelected
                            ? Icon(
                                Icons.check_circle,
                                size: 32,
                                color: language.color,
                              )
                            : Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 24,
                                color: language.color.withOpacity(0.5),
                              ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}