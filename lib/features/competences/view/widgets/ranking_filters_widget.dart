// lib/features/competences/view/widgets/ranking_filters_widget.dart

import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

class RankingFiltersWidget extends ConsumerWidget {
  const RankingFiltersWidget({super.key});

  /// 💡 Detecta si el dispositivo es de gama baja o un emulador lento.
  bool _shouldShowLottie(BuildContext context) {
    if (kIsWeb) return true; // Web siempre puede mostrar Lottie.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;

    final media = MediaQuery.of(context);
    final pixelDensity = media.devicePixelRatio;
    final width = media.size.width;
    final height = media.size.height;

    // 🔍 Heurística simple: si tiene baja resolución o baja densidad, lo consideramos "low-end".
    final bool isLowEnd = pixelDensity < 2.2 && (width * height) < 900000;

    if (isLowEnd) debugPrint('[Lottie] Dispositivo detectado como gama baja → se desactiva la animación.');
    else debugPrint('[Lottie] Dispositivo compatible → animación activa.');

    return !isLowEnd;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final selectedLang = ref.watch(selectedLanguageProvider);
    final allLangs = ref.watch(allLanguagesProvider);

    final bool showLottie = _shouldShowLottie(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        /// 🎬 Fondo animado si el dispositivo lo soporta
        if (showLottie)
          Positioned.fill(
            child: Opacity(
              opacity: brightness == Brightness.dark ? 0.15 : 0.25,
              child: Lottie.asset(
                'assets/animations/background_train.json',
                fit: BoxFit.cover,
                repeat: true,
                animate: ModalRoute.of(context)?.isCurrent ?? true,
                errorBuilder: (context, error, stack) {
                  debugPrint('[Lottie] Error al cargar animación: $error');
                  return const SizedBox();
                },
              ),
            ),
          )
        else
          /// 🌈 Fondo degradado alternativo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.surfaceVariant.withOpacity(0.15),
                    colors.surface.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

        /// 📋 Contenido principal con efecto de cristal
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    /// --- FILTRO DE LENGUAJE ---
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: colors.surfaceContainer,
                          foregroundColor: colors.onSurfaceVariant,
                          selectedForegroundColor: colors.onPrimary,
                          selectedBackgroundColor: colors.primary,
                        ),
                        segments: allLangs.entries.map((entry) {
                          return ButtonSegment<int>(
                            value: entry.key,
                            icon: Image.asset(
                              'assets/${entry.value['logo']!}',
                              width: 20,
                              height: 20,
                            ),
                            label: Text(entry.value['name']!),
                          );
                        }).toList(),
                        selected: {selectedLang},
                        onSelectionChanged: (newSelection) {
                          ref.read(selectedLanguageProvider.notifier).state =
                              newSelection.first;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// --- FILTRO DE TIEMPO ---
                    const _TimeFilterTabs(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeFilterTabs extends ConsumerWidget {
  const _TimeFilterTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);
    final allDifficulties = ref.watch(allDifficultiesProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: allDifficulties.entries.map((entry) {
        final isSelected = selectedDifficulty == entry.key;
        return GestureDetector(
          onTap: () {
            ref.read(selectedDifficultyProvider.notifier).state = entry.key;
          },
          child: Column(
            children: [
              Text(
                entry.value,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                width: isSelected ? 40 : 0,
                color: colors.primary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
