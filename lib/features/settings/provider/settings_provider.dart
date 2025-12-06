import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';
import 'package:kitsucode/features/settings/repository/settings_repository.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, PreferenciasUsuarioModel>(() {
      return SettingsNotifier();
    });

class SettingsNotifier extends AsyncNotifier<PreferenciasUsuarioModel> {
  Timer? _debounce;

  @override
  Future<PreferenciasUsuarioModel> build() async {
    final authState = ref.watch(authStateProvider);

    ref.onDispose(() {
      _debounce?.cancel();
    });

    return authState.when(
      data: (data) {
        if (data.session == null) {
          throw Exception('Usuario no autenticado para cargar settings');
        }

        final repository = ref.read(settingsRepositoryProvider);
        return repository.getPreferencias();
      },
      loading: () {
        return Completer<PreferenciasUsuarioModel>().future;
      },
      error: (e, s) {
        throw Exception('Error de autenticación subyacente: $e');
      },
    );
  }

  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  Future<void> updateTemaVisual(String tema) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.temaVisual == tema) return;

    state = AsyncData(currentState.copyWith(temaVisual: tema));

    try {
      await _repository.updatePreferencia({'tema_visual': tema});
    } catch (e) {
      state = AsyncData(currentState);
    }
  }

  Future<void> updateSonidoEfectos(bool estaActivado) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(sonidoEfectos: estaActivado));

    try {
      await _repository.updatePreferencia({'sonido_efectos': estaActivado});
    } catch (e) {
      state = AsyncData(currentState);
    }
  }

  void updateVolumenAudio(double volumen) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(volumenAudio: volumen));

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _repository.updatePreferencia({'volumen_audio': volumen});
      } catch (e, s) {
        state = AsyncError(e, s);
      }
    });
  }
}
