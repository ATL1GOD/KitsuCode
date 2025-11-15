// lib/features/challenge/view/feedback/challenge_failure_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- FUSIÓN: Se mantiene TU import de navigation_tracker_provider ---
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir los enlaces
import 'package:kitsucode/core/providers/app_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// --- Modelo Temporal de Recursos ---
class RecursoModel {
  final String titulo;
  final String url;

  RecursoModel({required this.titulo, required this.url});

  factory RecursoModel.fromJson(Map<String, dynamic> json) {
    return RecursoModel(
      titulo: json['titulo'] as String,
      url: json['url'] as String,
    );
  }
}
// ------------------------------------

class ChallengeFailureView extends ConsumerWidget {
  final List<RecursoModel> recursos;

  const ChallengeFailureView({super.key, required this.recursos});

  // --- Función helper para obtener el Tema ---
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

  // --- Función para abrir URL ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) debugPrint('No se pudo lanzar $urlString');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtenemos el tema del lenguaje actual
    final appBarState = ref.watch(appBarProvider);
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName,
      Theme.of(context).brightness,
    );
    final colorScheme = challengeTheme.colorScheme;
    final textTheme = challengeTheme.textTheme;

    // 2. Envolvemos el Scaffold en el Tema del lenguaje
    return PopScope(
      canPop: false, // Bloquear el botón de retroceso y el gesto de swipe back
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

                  // --- Animación o Ilustración ---
                  Image.asset(
                    'assets/images/zorro_oops.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  // --- Mensaje de Ánimo ---
                  Text(
                    '¡No te rindas!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme
                          .error, // Usamos el color de error del tema
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sigue reforzando este tema',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Sección de Recursos ---
                  Text(
                    'Recursos Oficiales',
                    textAlign: TextAlign.left,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: (recursos.isEmpty)
                          ? Center(
                              child: Text(
                                'No hay recursos disponibles para este reto.',
                                style: textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              itemCount: recursos.length,
                              itemBuilder: (context, index) {
                                final recurso = recursos[index];
                                return ListTile(
                                  leading: Icon(
                                    Icons.menu_book,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    recurso.titulo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    _launchURL(recurso.url);
                                  },
                                );
                              },
                            ),
                    ),
                  ),

                  const Spacer(),

                  // --- Botón de Continuar ---
                  // --- FUSIÓN: Se usa TU 'onPressed' (dxniel7) ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      ref.read(appBarProvider.notifier).fetchStats();

                      // El resto de tu lógica se queda igual
                      ref.read(oldStatsValuesProvider.notifier).state = null;
                      ref.read(shouldRefreshStatsProvider.notifier).state = false;

                      if (!context.mounted) return;

                      final returnPath = ref.read(navigationReturnPathProvider);
                      ref.read(navigationReturnPathProvider.notifier).state = '/home';
                      context.go(returnPath);
                    },
                    child: const Text(
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
          ), // Cierra SafeArea
        ), // Cierra Scaffold
      ), // Cierra Theme
    ); // Cierra PopScope
  }
}
