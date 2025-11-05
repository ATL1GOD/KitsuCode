import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

// --- DISTRIBUIDOR DE ESTADO PARA EL JUEGO DE PUZZLE
final puzzleProvider = StateNotifierProvider.autoDispose<PuzzleNotifier, PuzzleState>(
  (ref) {
    // Lanza un error. El Loader (PuzzleLoaderPage)
    // se encargará de anular (override) esto y crear el Notifier.
    throw UnimplementedError('PuzzleProvider no fue inicializado por el Loader');
  },
);

// --- ENUM 
enum PuzzleStatus {
  playing,
  correct,
  incorrect,
}

// --- PuzzleState 
class PuzzleState {
  final bool isLoading;
  final String? error;
  final PuzzleChallengeModel? challenge;
  final Map<String, PuzzleOption?> filledBlanks;
  final List<PuzzleOption> availableOptions;
  final PuzzleStatus status;

  PuzzleState({
    this.isLoading = true,
    this.error,
    this.challenge,
    this.filledBlanks = const {},
    this.availableOptions = const [],
    this.status = PuzzleStatus.playing,
  });

  PuzzleState copyWith({
    bool? isLoading,
    String? error,
    PuzzleChallengeModel? challenge,
    Map<String, PuzzleOption?>? filledBlanks,
    List<PuzzleOption>? availableOptions,
    PuzzleStatus? status,
  }) {
    return PuzzleState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      challenge: challenge ?? this.challenge,
      filledBlanks: filledBlanks ?? this.filledBlanks,
      availableOptions: availableOptions ?? this.availableOptions,
      status: status ?? this.status,
    );
  }
}

// --- PuzzleNotifier
class PuzzleNotifier extends StateNotifier<PuzzleState> {
  // Recibe el JSON (contenido) en el constructor.
  PuzzleNotifier(Map<String, dynamic> challengeContent) : super(PuzzleState()) {
    // Inicializa el juego con el contenido recibido.
    _initializePuzzle(challengeContent);
  }

  // --- MÉTODO DE INICIALIZACIÓN 
  void _initializePuzzle(Map<String, dynamic> challengeContent) {
    try {
      // 1. Parsea el JSON que recibimos
      final challenge = PuzzleChallengeModel.fromJson(challengeContent);

      // 2. Prepara los huecos vacíos
      final initialFilledBlanks = {
        for (var line in challenge.lines)
          if (line is BlankLine) line.id: null
      };

      // --- 3. LÓGICA PARA OPCIONES 
      final optionsMap = {
        for (var option in challenge.options) option.id : option
      };
      final List<PuzzleOption> optionsParaJugar = [];
      for (var line in challenge.lines) {
        if (line is BlankLine) {
          final optionId = line.correctOptionId; 
          final baseOption = optionsMap[optionId]; 
          if (baseOption != null) {
            optionsParaJugar.add(
              PuzzleOption(id: baseOption.id, text: baseOption.text) 
            );
          }
        }
      }
      for (var option in challenge.options) {
        // Verificamos si la opción ya está en la lista para jugar.
        if (!optionsParaJugar.any((o) => o.id == option.id)) {
           // 'option' viene del .fromJson() y el constructor le dio un 'uniqueId'
           optionsParaJugar.add(
             PuzzleOption(id: option.id, text: option.text)
           );
        }
      }
      optionsParaJugar.shuffle();
      // --- FIN DE LA LÓGICA PARA OPCIONES ---

      // 4. Establece el estado inicial del juego
      state = state.copyWith(
        isLoading: false, 
        challenge: challenge,
        filledBlanks: initialFilledBlanks,
        availableOptions: optionsParaJugar,
        status: PuzzleStatus.playing,
      );
    } catch (e) {
      // Si el JSON está mal, capturamos el error
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- MÉTODOS PARA INTERACTUAR CON EL JUEGO
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
    if (optionInTarget != null && !newAvailableOptions.contains(optionInTarget)) {
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

  void checkSolution() {
    if (state.challenge == null) return;
    for (var line in state.challenge!.lines) {
      if (line is BlankLine) {
        final userOption = state.filledBlanks[line.id];
        if (userOption == null || userOption.id != line.correctOptionId) {
          state = state.copyWith(status: PuzzleStatus.incorrect);
          return;
        }
      }
    }
    state = state.copyWith(status: PuzzleStatus.correct);
  }
} 