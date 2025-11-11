import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';
import 'package:kitsucode/features/settings/repository/settings_repository.dart';

// --- ¡CAMBIO 1: El Provider! ---
// Se convierte en AsyncNotifierProvider.
// Ahora SÍ tendrá el getter ".future"
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, PreferenciasUsuarioModel>(() {
  return SettingsNotifier();
});

// --- ¡CAMBIO 2: El Notifier! ---
// Se convierte de StateNotifier a AsyncNotifier
class SettingsNotifier extends AsyncNotifier<PreferenciasUsuarioModel> {
  Timer? _debounce;

  // --- ¡CAMBIO 3: 'build()' reemplaza a 'loadPreferencias()' ---
  // Esta función se llama automáticamente para obtener el estado inicial
  @override
  Future<PreferenciasUsuarioModel> build() async {
    // ¡NUEVO! Esperar a que la autenticación esté lista
    final authState = await ref.watch(authStateProvider.future);
    
    // Si no hay sesión, lanza un error
    if (authState.session == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Obtenemos el repositorio usando 'ref' (es parte de AsyncNotifier)
    final repository = ref.watch(settingsRepositoryProvider);

    // 'ref.onDispose' es el nuevo 'dispose()'
    ref.onDispose(() {
      _debounce?.cancel();
    });
    
    // El 'return' de build es el estado inicial
    return repository.getPreferencias();
  }

  // Método helper para no repetir código
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  // Actualizar Tema Visual
  Future<void> updateTemaVisual(String tema) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.temaVisual == tema) return;

    // 1. Actualización optimista: actualiza la UI al instante
    state = AsyncData(currentState.copyWith(temaVisual: tema));

    // 2. Intenta actualizar la BD (usando tu método original)
    try {
      await _repository.updatePreferencia({'tema_visual': tema});
    } catch (e) {
      // 3. Si falla, revierte el estado y reporta el error
      // (Tu lógica original revertía al estado anterior)
      state = AsyncData(currentState);
      // Opcional: reportar el error
      // state = AsyncError(e, s); 
    }
  }

  // Actualizar Efectos de Sonido
  Future<void> updateSonidoEfectos(bool estaActivado) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Actualización optimista
    state = AsyncData(currentState.copyWith(sonidoEfectos: estaActivado));

    try {
      // (usando tu método original)
      await _repository.updatePreferencia({'sonido_efectos': estaActivado});
    } catch (e) {
      // Revertir
      state = AsyncData(currentState);
      // Opcional: reportar el error
      // state = AsyncError(e, s);
    }
  }

  // Actualizar Volumen de Audio (con Debounce)
  void updateVolumenAudio(double volumen) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Actualización optimista
    state = AsyncData(currentState.copyWith(volumenAudio: volumen));

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // (usando tu método original)
        await _repository.updatePreferencia({'volumen_audio': volumen});
      } catch (e, s) {
        // Reportar error
        state = AsyncError(e, s);
      }
    });
  }
  
}
