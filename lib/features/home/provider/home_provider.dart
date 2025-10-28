import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/repository/home_repository.dart';

// 1. El Provider (ViewModel)
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  @override
  Future<List<SectionData>> build() async {
    return _fetchSections();
  }

  Future<List<SectionData>> _fetchSections() async {
    final repository = ref.watch(sectionRepositoryProvider);
    return repository.getSections();
  }

  Future<void> refreshSections() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSections());
  }
}
