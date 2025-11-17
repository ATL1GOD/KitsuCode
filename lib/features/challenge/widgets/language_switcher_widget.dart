// lib/features/settings/widgets/language_switcher_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/challenge/provider/language_completion_provider.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget para cambiar entre lenguajes COMPLETADOS
/// Muestra solo los lenguajes que el usuario ya dominó
class LanguageSwitcherWidget extends ConsumerStatefulWidget {
  const LanguageSwitcherWidget({super.key});

  @override
  ConsumerState<LanguageSwitcherWidget> createState() =>
      _LanguageSwitcherWidgetState();
}

class _LanguageSwitcherWidgetState
    extends ConsumerState<LanguageSwitcherWidget> {
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar los lenguajes completados al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId != null) {
        ref
            .read(languageCompletionProvider.notifier)
            .checkLanguageCompletion(userId);
      }
    });
  }

  Future<void> _switchLanguage(String languageName) async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Actualizar lenguaje (normalizar a minúsculas)
      await ref
          .read(languageCompletionProvider.notifier)
          .updateFavoriteLanguage(userId, languageName.toLowerCase());

      // 🔥 CRÍTICO: Volver a verificar lenguajes completados
      await ref
          .read(languageCompletionProvider.notifier)
          .checkLanguageCompletion(userId);

      // Actualizar el appBar
      await ref.read(appBarProvider.notifier).fetchStats();

      if (mounted) {
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cambiado a $languageName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Colapsar el widget
        setState(() {
          _isExpanded = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getLanguageColor(String languageName) {
    final normalized = languageName.trim().toLowerCase();
    switch (normalized) {
      case 'python':
        return const Color(0xFF3776AB);
      case 'java':
        return const Color(0xFFF89820);
      case 'c':
        return const Color(0xFF00599C);
      default:
        return Colors.orange;
    }
  }

  IconData _getLanguageIcon(String languageName) {
    final normalized = languageName.trim().toLowerCase();
    switch (normalized) {
      case 'python':
        return Icons.code;
      case 'java':
        return Icons.coffee;
      case 'c':
        return Icons.memory;
      default:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageCompletionProvider);
    final currentLanguage = languageState.currentLanguage;
    final unlockedLanguages = languageState.unlockedLanguages;

    // Si solo tiene un lenguaje o ninguno, no mostrar el switcher
    if (unlockedLanguages.length <= 1) {
      return const SizedBox.shrink();
    }

    final currentColor = _getLanguageColor(currentLanguage);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header - Siempre visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícono del lenguaje actual
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getLanguageIcon(currentLanguage),
                      color: currentColor,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Info del lenguaje
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lenguaje Actual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLanguage.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de lenguajes desbloqueados
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${unlockedLanguages.length}/3',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Flecha de expansión
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Lista de lenguajes - Se expande/colapsa
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...unlockedLanguages.map((language) {
                        final isCurrentLanguage =
                            language.trim().toLowerCase() ==
                                currentLanguage.trim().toLowerCase();
                        final color = _getLanguageColor(language);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: InkWell(
                            onTap: isCurrentLanguage || _isLoading
                                ? null
                                : () => _switchLanguage(language),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentLanguage
                                    ? color.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrentLanguage
                                      ? color
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getLanguageIcon(language),
                                    color: isCurrentLanguage
                                        ? color
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      language.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isCurrentLanguage
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isCurrentLanguage
                                            ? color
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  if (isCurrentLanguage)
                                    Icon(
                                      Icons.check_circle,
                                      color: color,
                                      size: 20,
                                    )
                                  else if (_isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 200.ms).slideX(
                              begin: -0.1,
                              end: 0,
                              duration: 300.ms,
                            );
                      }),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}