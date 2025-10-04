// lib/features/competences/view/widgets/ranking_filters_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

class RankingFiltersWidget extends ConsumerWidget {
  const RankingFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    final selectedLang = ref.watch(selectedLanguageProvider);
    final selectedTimeFilter = ref.watch(selectedDifficultyProvider); 

    final allLangs = ref.watch(allLanguagesProvider); 
    final allTimeFilters = ref.watch(allDifficultiesProvider);
    
    final langData = allLangs[selectedLang] ?? {'name': 'Python', 'logo': 'images/placeholder.png'};
    
    // 💡 FIX CRÍTICO: Retornamos un Padding (RenderBox) para que encaje en la Column.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
      child: FadeInDown( // La animación es solo del contenido de la fila
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Filtro de Lenguaje (CON LOGO Y FLEXIBLE)
            Flexible(
              child: _buildLanguageDropdown(
                context,
                ref, // Pasamos el WidgetRef para la corrección del 'read'
                logoPath: langData['logo']!,
                items: allLangs.keys.toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    ref.read(selectedLanguageProvider.notifier).state = newValue;
                  }
                },
                colors: colors,
                value: selectedLang,
                names: allLangs.map((key, value) => MapEntry(key, value['name']!)), 
              ),
            ),

            const SizedBox(width: 10), 
            
            // 2. Filtro de Tiempo (Mejorado)
            Flexible( 
              child: _buildFilterDropdown( 
                context,
                label: allTimeFilters[selectedTimeFilter]!,
                icon: Icons.timer_outlined, 
                items: allTimeFilters.keys.toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    ref.read(selectedDifficultyProvider.notifier).state = newValue; 
                  }
                },
                colors: colors,
                value: selectedTimeFilter,
                names: allTimeFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ----------------------------------------------------
  // HELPER 1: Dropdown de Lenguaje (CON LOGO)
  // ----------------------------------------------------
  Widget _buildLanguageDropdown(
    BuildContext context, 
    WidgetRef ref, // ACEPTAMOS WidgetRef
    {
    required String logoPath,
    required List<int> items,
    required void Function(int?) onChanged,
    required ColorScheme colors,
    required int value,
    required Map<int, String> names,
  }) {
    // 💡 CORRECCIÓN: Usamos ref.read para acceder a los providers (Soluciona el error)
    final allLangsMap = ref.read(allLanguagesProvider); 

    return Container(
      // CORRECCIÓN Estética: Comprimimos el padding horizontal
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha( (255 * 0.4).round() ), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withAlpha( (255 * 0.3).round() )), 
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.primary, size: 20),
          // 💡 CORRECCIÓN LOGO: El Hint es lo que se ve cuando no está abierto.
          // Esto soluciona la duplicidad de logos.
          hint: Row(
            children: [
              Image.asset('assets/$logoPath', height: 22, width: 22, errorBuilder: (c, e, s) => const Icon(Icons.code, size: 22)),
              const SizedBox(width: 8),
              Text(names[value]!, style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
            ],
          ),
          
          style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold),
          dropdownColor: colors.surfaceContainerHigh, 
          
          items: items.map((int id) {
            final itemData = allLangsMap[id];
            return DropdownMenuItem<int>(
              value: id,
              // Muestra el logo y el nombre en las opciones (DropdownItems)
              child: Row(
                children: [
                  // 💡 CORRECCIÓN RUTA: Usamos 'assets/' + la ruta sin prefijo
                  Image.asset('assets/${itemData?['logo'] ?? 'images/placeholder.png'}', 
                    height: 20, 
                    width: 20,
                    errorBuilder: (c, e, s) => const Icon(Icons.code, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(itemData?['name'] ?? 'N/A'),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  // ----------------------------------------------------
  // HELPER 2: Filtro de Tiempo (Corrige el espaciado)
  // ----------------------------------------------------
  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<int> items,
    required void Function(int?) onChanged,
    required ColorScheme colors,
    required int value,
    required Map<int, String> names,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha( (255 * 0.4).round() ), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withAlpha( (255 * 0.3).round() )), 
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.primary, size: 20),

           // 💡 CORRECCIÓN ICONO: Usamos selectedItemBuilder para mostrar el icono y el texto
          selectedItemBuilder: (BuildContext context) {
            return items.map((int id) {
              // Este es el widget que se muestra cuando este ID está seleccionado
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: colors.primary, size: 20), // El icono del reloj
                    const SizedBox(width: 4), 
                    Text(names[id] ?? 'N/A', style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList();
          },
          // 💡 CRÍTICO: Usamos Hint para arreglar el espaciado y poner icono/texto juntos
          hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colors.primary, size: 20),
                const SizedBox(width: 4), // Espacio comprimido
                Text(label, style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
              ],
            ),
          style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold),
          dropdownColor: colors.surfaceContainerHigh, 
          items: items.map((int id) {
            return DropdownMenuItem<int>(
              value: id,
              child: Text(names[id] ?? 'N/A'), 
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}