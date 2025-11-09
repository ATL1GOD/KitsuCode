// [COMIENZO DEL ARCHIVO home_provider.dart]
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
// ¡¡Importa la nueva clase HomeMapData!!
import 'package:kitsucode/features/home/repository/home_repository.dart';

// Importamos el provider del languageId SOLAMENTE.
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

// 1. El Provider (ViewModel)
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  @override
  Future<List<SectionData>> build() async {
    // --- ¡DEBUG! ---
    debugPrint("--- HomeViewModel: build() SE EJECUTÓ ---");

    // 1. Observamos SOLO el languageId (no todo el appBarState)
    //    Esto evita rebuilds cuando cambian vidas/trofeos/racha
    final languageId = ref.watch(currentLanguageIdProvider);

    // --- ¡DEBUG! ---
    debugPrint("HomeViewModel: 'languageId' observado -> $languageId");

    // 2. Si el ID es 0, retornamos una lista vacía
    if (languageId == 0) {
      
      // --- ¡DEBUG! ---
      debugPrint("HomeViewModel: languageId es 0. Retornando mapa vacío [].");
      
    final appBarState = ref.watch(appBarProvider);
    if (appBarState.isLoading || appBarState.languageId == 0) {
      return [];
    }
    return _fetchSections(appBarState.languageId);

    // --- ¡DEBUG! ---
    debugPrint("HomeViewModel: Llamando a _fetchSections con ID: $languageId");

    // 3. Una vez que tenemos el ID del lenguaje, cargamos las secciones.
    return _fetchSections(languageId);
  }

  // --- ¡¡MÉTODO CLAVE MODIFICADO!! ---
  Future<List<SectionData>> _fetchSections(int languageId) async {
    final repository = ref.read(sectionRepositoryProvider);

    // 1. Obtenemos los datos (ambas listas)
    final HomeMapData homeData = await repository.getHomeMapData(languageId);

    final List<SectionData> sections = homeData.sections;
    final Set<int> completedIds = homeData.completedLevelIds;

    // 2. Aplicamos el PROGRESO (isCompleted) manualmente
    //    Usamos 'map' para recrear las listas con los datos actualizados
    final List<SectionData> sectionsWithProgress = sections.map((section) {
      // Creamos la nueva lista de niveles para esta sección
      final List<LevelData> updatedLevels = section.levels.map((level) {
        // Comprobamos si el ID de este nivel está en el Set de completados
        final bool isCompleted = completedIds.contains(level.idNivel);

        return level.copyWith(
          isCompleted: isCompleted, // ¡Aplicamos el progreso!
        );
      }).toList(); // Fin .map de niveles

      // Devolvemos la sección con su nueva lista de niveles
      return section.copyWith(levels: updatedLevels);
    }).toList(); // Fin .map de secciones

    // --- Tus prints de debug (¡ahora deberían funcionar!) ---
    debugPrint("--- DATOS ANTES DE LÓGICA (PROGRESO APLICADO) ---");
    for (var sec in sectionsWithProgress) {
      for (var lvl in sec.levels) {
        debugPrint(
          'Seccion ${sec.etapa}, Nivel ${lvl.nivel} (ID: ${lvl.idNivel}), isCompleted: ${lvl.isCompleted}',
        );
      }
    }
    // --- Fin Debug ---

    // 3. ¡Aplicamos la lógica de BLOQUEO (isLocked)!
    final List<SectionData> finalSections =
        SectionData.applySequentialSectionLock(sectionsWithProgress);

    // --- Debug final ---
    debugPrint("--- DATOS DESPUÉS DE LÓGICA (BLOQUEO APLICADO) ---");
    for (var sec in finalSections) {
      for (var lvl in sec.levels) {
        debugPrint(
          'Seccion ${sec.etapa}, Nivel ${lvl.nivel}, isLocked: ${lvl.isLocked}',
        );
      }
    }
    // --- Fin Debug ---

    // 4. Devolvemos la lista final a la UI
    return finalSections;
  }

  // (Tu función de refresh)
  Future<void> refreshSections() async {
    state = const AsyncValue.loading();
    final languageId = ref.read(currentLanguageIdProvider);
    if (languageId == 0) {
      state = await AsyncValue.guard(() => Future.value([]));
      return;
    }
    state = await AsyncValue.guard(() => _fetchSections(languageId));
  }
}
// [FIN DEL ARCHIVO home_provider.dart]