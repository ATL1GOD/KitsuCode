// lib/features/puzzle_game/provider/puzzle_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

// --- 1. IMPORTAR LOS PROVIDERS QUE NECESITAMOS ---
import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- ¡AÑADIR ESTA IMPORTACIÓN! ---
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// --- DISTRIBUIDOR DE ESTADO
final puzzleProvider =
    StateNotifierProvider.autoDispose<PuzzleNotifier, PuzzleState>((ref) {
      // Este error es correcto. Se anula en PuzzleLoaderPage.
      throw UnimplementedError(
        'PuzzleProvider debe ser anulado (overridden) por PuzzleLoaderPage '
        'con el id_reto y el contenido del reto.',
      );
    });

// --- ENUM (Sin cambios)
enum PuzzleStatus { playing, correct, incorrect }

// --- PuzzleState (MODIFICADO)
class PuzzleState {
  final int challengeId; // El id_reto de Supabase
  final bool isLoading;
  final String? error;
  final PuzzleChallengeModel? challenge;
  final Map<String, PuzzleOption?> filledBlanks;
  final List<PuzzleOption> availableOptions;
  final PuzzleStatus status;

  PuzzleState({
    this.challengeId = 0, // Valor por defecto
    this.isLoading = true,
    this.error,
    this.challenge,
    this.filledBlanks = const {},
    this.availableOptions = const [],
    this.status = PuzzleStatus.playing,
  });

  // copyWith (MODIFICADO)
  PuzzleState copyWith({
    int? challengeId,
    bool? isLoading,
    String? error,
    PuzzleChallengeModel? challenge,
    Map<String, PuzzleOption?>? filledBlanks,
    List<PuzzleOption>? availableOptions,
    PuzzleStatus? status,
  }) {
    return PuzzleState(
      challengeId: challengeId ?? this.challengeId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      challenge: challenge ?? this.challenge,
      filledBlanks: filledBlanks ?? this.filledBlanks,
      availableOptions: availableOptions ?? this.availableOptions,
      status: status ?? this.status,
    );
  }
}

// --- PuzzleNotifier (MODIFICADO)
class PuzzleNotifier extends StateNotifier<PuzzleState> {
  // Guardamos 'ref' para poder llamar a otros providers
  final Ref _ref;

  // El constructor ahora acepta el ID del reto y 'ref'
  PuzzleNotifier(
    Map<String, dynamic> challengeContent,
    int challengeId, // (ej: 2)
    this._ref,
  ) : super(PuzzleState(challengeId: challengeId)) {
    // Guarda el ID en el estado
    _initializePuzzle(challengeContent);
  }

  // --- MÉTODO DE INICIALIZACIÓN (Sin cambios)
  void _initializePuzzle(Map<String, dynamic> challengeContent) {
    try {
      final challenge = PuzzleChallengeModel.fromJson(challengeContent);
      final initialFilledBlanks = {
        for (var line in challenge.lines)
          if (line is BlankLine) line.id: null,
      };
      final optionsMap = {
        for (var option in challenge.options) option.id: option,
      };
      final List<PuzzleOption> optionsParaJugar = [];
      for (var line in challenge.lines) {
        if (line is BlankLine) {
          final optionId = line.correctOptionId;
          final baseOption = optionsMap[optionId];
          if (baseOption != null) {
            optionsParaJugar.add(
              PuzzleOption(id: baseOption.id, text: baseOption.text),
            );
          }
        }
      }
      for (var option in challenge.options) {
        if (!optionsParaJugar.any((o) => o.id == option.id)) {
          optionsParaJugar.add(PuzzleOption(id: option.id, text: option.text));
        }
      }
      optionsParaJugar.shuffle();
      state = state.copyWith(
        isLoading: false,
        challenge: challenge,
        filledBlanks: initialFilledBlanks,
        availableOptions: optionsParaJugar,
        status: PuzzleStatus.playing,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- MÉTODOS PARA INTERACTUAR (Sin cambios)
  void onOptionDroppedOnBlank(String blankId, PuzzleOption droppedOption) {
    if (state.status == PuzzleStatus.correct) return;

    PuzzleStatus newStatus = (state.status == PuzzleStatus.incorrect)
        ? PuzzleStatus.playing
        : state.status;
    var newFilledBlanks = Map<String, PuzzleOption?>.from(state.filledBlanks);
    var newAvailableOptions = List<PuzzleOption>.from(state.availableOptions);

    newAvailableOptions.remove(droppedOption);

    String? sourceBlankId;
    for (final entry in newFilledBlanks.entries) {
      if (entry.value == droppedOption) {
        sourceBlankId = entry.key;
        break;
      }
    }
    if (sourceBlankId != null) {
      newFilledBlanks[sourceBlankId] = null;
    }

    final PuzzleOption? optionInTarget = newFilledBlanks[blankId];
    if (optionInTarget != null &&
        !newAvailableOptions.contains(optionInTarget)) {
      newAvailableOptions.add(optionInTarget);
    }

    newFilledBlanks[blankId] = droppedOption;

    state = state.copyWith(
      filledBlanks: newFilledBlanks,
      availableOptions: newAvailableOptions,
      status: newStatus,
    );
  }

  void onOptionDroppedOnBank(PuzzleOption droppedOption) {
    if (state.status == PuzzleStatus.correct) return;

    PuzzleStatus newStatus = (state.status == PuzzleStatus.incorrect)
        ? PuzzleStatus.playing
        : state.status;
    var newFilledBlanks = Map<String, PuzzleOption?>.from(state.filledBlanks);
    var newAvailableOptions = List<PuzzleOption>.from(state.availableOptions);

    String? sourceBlankId;
    for (final entry in newFilledBlanks.entries) {
      if (entry.value == droppedOption) {
        sourceBlankId = entry.key;
        break;
      }
    }
    if (sourceBlankId != null) {
      newFilledBlanks[sourceBlankId] = null;
    }
    if (!newAvailableOptions.contains(droppedOption)) {
      newAvailableOptions.add(droppedOption);
    }
    state = state.copyWith(
      filledBlanks: newFilledBlanks,
      availableOptions: newAvailableOptions,
      status: newStatus,
    );
  }

  // --- ¡CAMBIO GRANDE! ---
  void checkSolution() async {
    if (state.challenge == null || state.status != PuzzleStatus.playing) return;

    const int tiempoQueTardo = 0;

    bool isCorrect = true;
    for (var line in state.challenge!.lines) {
      if (line is BlankLine) {
        final userOption = state.filledBlanks[line.id];
        if (userOption == null || userOption.id != line.correctOptionId) {
          isCorrect = false;
          break;
        }
      }
    }

    final challengeRepo = _ref.read(challengeRepositoryProvider);

    if (isCorrect) {
      // --- SI GANÓ ---
      state = state.copyWith(status: PuzzleStatus.correct);

      try {
        await challengeRepo.submitChallengeAttempt(
          retoId: state.challengeId,
          fueExitoso: true,
          tiempoQueTardo: tiempoQueTardo,
        );

        // 1. Refrescar los trofeos en el AppBar
        _ref.read(appBarProvider.notifier).fetchStats();

        // --- ¡AQUÍ ESTÁ LA SOLUCIÓN! ---
        // 2. Invalidar el provider del ranking para que se actualice
        // (Usa 'globalRankingProvider', que es el nombre correcto)
        _ref.invalidate(globalRankingProvider);
      } catch (e) {
        debugPrint("Error al enviar intento exitoso: $e");
      }
    } else {
      // --- SI PERDIÓ ---
      state = state.copyWith(status: PuzzleStatus.incorrect);

      try {
        await challengeRepo.submitChallengeAttempt(
          retoId: state.challengeId,
          fueExitoso: false,
          tiempoQueTardo: tiempoQueTardo,
        );
      } catch (e) {
        debugPrint("Error al enviar intento fallido: $e");
      }
    }
  }
}
