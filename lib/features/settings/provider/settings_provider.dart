import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';
import 'package:kitsucode/features/settings/repository/settings_repository.dart';

// --- El Provider ---
// (Esto ya estaba bien en tu código)
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, PreferenciasUsuarioModel>(() {
  return SettingsNotifier();
});

// --- El Notifier ---
// (Esto ya estaba bien en tu código)
class SettingsNotifier extends AsyncNotifier<PreferenciasUsuarioModel> {
  Timer? _debounce;

  // --- ¡CAMBIO 3: 'build()' REFACTORIZADO (NO BLOQUEANTE)! ---
  // Esta es la corrección clave, ahora con formato limpio.
  @override
  Future<PreferenciasUsuarioModel> build() async {
    // 1. OBSERVAMOS el estado de auth, sin 'await' y sin '.future'
    final authState = ref.watch(authStateProvider);

    // 'ref.onDispose' es el nuevo 'dispose()'
    ref.onDispose(() {
      _debounce?.cancel();
    });

    // 2. Usamos 'when' para manejar los 3 casos de authState
    // Esto se ejecuta SINCRÓNICAMENTE.
    return authState.when(
      data: (data) {
        // 3. Caso 'data': Auth SÍ cargó
        if (data.session == null) {
          // No hay usuario, lanzamos error.
          throw Exception('Usuario no autenticado para cargar settings');
        }
        
        // Hay usuario, AHORA SÍ podemos hacer la llamada a la BD.
        final repository = ref.read(settingsRepositoryProvider);
        return repository.getPreferencias(); // Este 'await' (implícito) está bien.
      },
      loading: () {
        // 4. Caso 'loading': Auth está cargando.
        // Mantenemos 'settingsProvider' en 'loading'
        // devolviendo un Futuro que nunca se completa.
        return Completer<PreferenciasUsuarioModel>().future;
      },
      error: (e, s) {
        // 5. Caso 'error': Auth falló, propagamos el error.
        throw Exception('Error de autenticación subyacente: $e');
      },
    );
  }


  // --- EL RESTO DE TU CÓDIGO PERMANECE EXACTAMENTE IGUAL ---

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