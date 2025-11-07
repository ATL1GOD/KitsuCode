// [COMIENZO DEL ARCHIVO home_provider.dart]
import 'package:flutter/foundation.dart'; // <-- ¡Asegúrate de importar esto para debugPrint!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/repository/home_repository.dart';

// Importamos el provider del AppBar.
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

// 1. El Provider (ViewModel) (sin cambios)
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel) (CON DEPURACIÓN)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  @override
  Future<List<SectionData>> build() async {
    // --- ¡DEBUG! ---
    debugPrint("--- HomeViewModel: build() SE EJECUTÓ ---");

    // 1. Observamos (watch) el estado del AppBar.
    final appBarState = ref.watch(appBarProvider);

    // --- ¡DEBUG! ---
    debugPrint(
      "HomeViewModel: 'appBarState' observado -> isLoading: ${appBarState.isLoading}, languageId: ${appBarState.languageId}",
    );

    // 2. Si el AppBar aún está cargando o tiene el ID 0,
    //    retornamos una lista vacía.
    if (appBarState.isLoading || appBarState.languageId == 0) {
      // --- ¡DEBUG! ---
      debugPrint(
        "HomeViewModel: Condición CUMPLIDA (loading o ID=0). Retornando mapa vacío [].",
      );

      return [];
    }

    // --- ¡DEBUG! ---
    debugPrint(
      "HomeViewModel: Condición FALSA. Llamando a _fetchSections con ID: ${appBarState.languageId}",
    );

    // 3. Una vez que tenemos el ID del lenguaje, cargamos las secciones.
    return _fetchSections(appBarState.languageId);
  }

  Future<List<SectionData>> _fetchSections(int languageId) async {
    final repository = ref.watch(sectionRepositoryProvider);

    // 1. Obtenemos los datos sin la lógica de bloqueo inter-secciones aplicada
    final List<SectionData> sections = await repository.getSections(
      languageId,
    ); //

    // 2. Aplicamos la lógica de bloqueo secuencial entre secciones
    return SectionData.applySequentialSectionLock(sections);
  }

  Future<void> refreshSections() async {
    state = const AsyncValue.loading();
    final languageId = ref.read(appBarProvider).languageId;

    if (languageId == 0) {
      state = await AsyncValue.guard(() => Future.value([]));
      return;
    }

    state = await AsyncValue.guard(() => _fetchSections(languageId));
  }
}
// [FIN DEL ARCHIVO home_provider.dart]