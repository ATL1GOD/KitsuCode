// [COMIENZO DEL ARCHIVO home_provider.dart]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/repository/home_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

// 1. El Provider (ViewModel)
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  @override
  Future<List<SectionData>> build() async {
    // 1. Observamos (watch) el estado del AppBar.
    final appBarState = ref.watch(appBarProvider);

    // 2. Si el AppBar aún está cargando o no tiene lenguaje,
    //    retornamos una lista vacía.
    if (appBarState.isLoading || appBarState.languageId == 0) {
      return [];
    }

    // 3. Una vez que tenemos el ID del lenguaje, cargamos las secciones.
    return _fetchSections(appBarState.languageId);
  }

  // --- MÉTODO CLAVE ---
  Future<List<SectionData>> _fetchSections(int languageId) async {
    final repository = ref.read(sectionRepositoryProvider); // (No 'watch')

    // 1. Obtenemos los datos "en crudo" (solo con 'isCompleted' marcado)
    final List<SectionData> sections = await repository.getSections(languageId);

    // 2. ¡Aplicamos la lógica de desbloqueo secuencial!
    //    Esto aplica los candados (isLocked = true) donde corresponda.
    return SectionData.applySequentialSectionLock(sections);
  }

  // (El resto de tu provider, ej. refreshSections)
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