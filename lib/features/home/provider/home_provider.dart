import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/repository/home_repository.dart';

// 1. El Provider (ViewModel)
// Este es el provider que tu VISTA observará
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  // El método 'build' es llamado automáticamente para
  // obtener el estado inicial.
  @override
  Future<List<SectionData>> build() async {
    // Pide al repositorio que cargue los datos
    return _fetchSections();
  }

  // Método privado para obtener los datos
  Future<List<SectionData>> _fetchSections() async {
    // 'ref.watch' obtiene el repositorio. Si el repositorio
    // cambiara, este notifier se reconstruiría.
    final repository = ref.watch(sectionRepositoryProvider);
    return repository.getSections();
  }

  // (Opcional) Puedes añadir métodos públicos para
  // interactuar con el estado, como recargar.
  Future<void> refreshSections() async {
    // Establece el estado a 'cargando'
    state = const AsyncValue.loading();
    // Vuelve a intentar la carga
    state = await AsyncValue.guard(() => _fetchSections());
  }
}
