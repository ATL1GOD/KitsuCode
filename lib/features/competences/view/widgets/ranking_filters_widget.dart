// lib/features/competences/view/widgets/ranking_filters_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

class RankingFiltersWidget extends ConsumerWidget {
  const RankingFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final selectedLang = ref.watch(selectedLanguageProvider);
    final allLangs = ref.watch(allLanguagesProvider);

    // Ahora el widget es transparente y se enfoca solo en su contenido.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        // Fondo translúcido con borde sutil
        decoration: BoxDecoration(
          color: colors.surface.withAlpha(26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline.withAlpha(51), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            //
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: colors.surfaceContainer.withAlpha(128),
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
                      cacheWidth: 40,
                      cacheHeight: 40,
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

            /// Pestañas de filtro de tiempo
            /// (Hoy, Semana, Mes, Todos)
            const _TimeFilterTabs(),
          ],
        ),
      ),
    );
  }
}

class _TimeFilterTabs extends ConsumerWidget {
  const _TimeFilterTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- CAMBIO 1: USA LOS PROVIDERS CORRECTOS ---
    final selectedTime = ref.watch(selectedTimeFilterProvider); // <-- Cambiado
    final allTimeFilters = ref.watch(allTimeFiltersProvider); // <-- Cambiado

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: allTimeFilters.entries.map((entry) {
        // <-- Cambiado
        final isSelected = selectedTime == entry.key; // <-- Cambiado
        return GestureDetector(
          onTap: () {
            // --- CAMBIO 2: ACTUALIZA EL PROVIDER CORRECTO ---
            ref.read(selectedTimeFilterProvider.notifier).state =
                entry.key; // <-- Cambiado
          },
          child: Column(
            children: [
              Text(
                entry.value,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
