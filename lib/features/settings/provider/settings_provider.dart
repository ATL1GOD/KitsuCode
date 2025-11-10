import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';
// ¡Este import ahora debería funcionar una vez que crees el archivo de arriba!
import 'package:kitsucode/features/settings/repository/settings_repository.dart';

// 1. El StateNotifier
class SettingsNotifier extends StateNotifier<AsyncValue<PreferenciasUsuarioModel>> {
  final SettingsRepository _repository;
  Timer? _debounce;

  SettingsNotifier(this._repository) : super(const AsyncLoading()) {
    loadPreferencias();
  }

  // Cargar las preferencias iniciales
  Future<void> loadPreferencias() async {
    state = const AsyncLoading();
    try {
      final preferencias = await _repository.getPreferencias();
      state = AsyncData(preferencias);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  // Actualizar Tema Visual
  Future<void> updateTemaVisual(String tema) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.temaVisual == tema) return;

    state = AsyncData(currentState.copyWith(temaVisual: tema));

    try {
      // ¡Corregido!
      await _repository.updatePreferencia({'tema_visual': tema});
    } catch (e) {
      // Si falla, revertir el estado
      state = AsyncData(currentState);
    }
  }

  // Actualizar Efectos de Sonido
  Future<void> updateSonidoEfectos(bool estaActivado) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(sonidoEfectos: estaActivado));

    try {
      // ¡Corregido!
      await _repository.updatePreferencia({'sonido_efectos': estaActivado});
    } catch (e) {
      state = AsyncData(currentState);
    }
  }

  // Actualizar Volumen de Audio (con Debounce)
  void updateVolumenAudio(double volumen) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(volumenAudio: volumen));

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // ¡Corregido!
        await _repository.updatePreferencia({'volumen_audio': volumen});
      } catch (e) {
        // No revertimos en el slider, solo logueamos
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// 2. El StateNotifierProvider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<PreferenciasUsuarioModel>>((ref) {
  // ¡Esto ahora debería funcionar!
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});