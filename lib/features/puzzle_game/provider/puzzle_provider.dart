// lib/features/puzzle_game/provider/puzzle_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;


// --- DISTRIBUIDOR DE ESTADO
final puzzleProvider = StateNotifierProvider.autoDispose<PuzzleNotifier, PuzzleState>(
  (ref) {
    // Este error es correcto. Se anula en PuzzleLoaderPage.
    throw UnimplementedError(
      'PuzzleProvider debe ser anulado (overridden) por PuzzleLoaderPage '
      'con el id_reto y el contenido del reto.'
    );
  },
);

// --- ENUM (Sin cambios)
enum PuzzleStatus {
  playing,
  correct,
  incorrect,
}

// --- PuzzleState (Corregido con isLoading y error) ---
@immutable
class PuzzleState {
  final PuzzleChallengeModel? challenge;
  final Map<String, PuzzleOption?> filledBlanks;
  final List<PuzzleOption> availableOptions;
  final PuzzleStatus status;
  
  // --- CAMPOS NUEVOS ---
  final int challengeId; 
  final int nivelId; // ← ¡AÑADIDO!
  final List<RecursoModel> recursos;

  // --- CAMPOS ORIGINALES (DE VUELTA) ---
  final bool isLoading; 
  final String? error;

  const PuzzleState({
    this.challenge,
    this.filledBlanks = const {},
    this.availableOptions = const [],
    this.status = PuzzleStatus.playing,
    this.challengeId = 0,
    this.nivelId = 0, // ← ¡AÑADIDO!
    this.recursos = const [],
    this.isLoading = true, // <-- Valor inicial
    this.error,
  });

  PuzzleState copyWith({
    PuzzleChallengeModel? challenge,
    Map<String, PuzzleOption?>? filledBlanks,
    List<PuzzleOption>? availableOptions,
    PuzzleStatus? status,
    int? challengeId,
    int? nivelId, // ← ¡AÑADIDO!
    List<RecursoModel>? recursos,
    bool? isLoading,
    String? error,
  }) {
    return PuzzleState(
      challenge: challenge ?? this.challenge,
      filledBlanks: filledBlanks ?? this.filledBlanks,
      availableOptions: availableOptions ?? this.availableOptions,
      status: status ?? this.status,
      challengeId: challengeId ?? this.challengeId,
      nivelId: nivelId ?? this.nivelId, // ← ¡AÑADIDO!
      recursos: recursos ?? this.recursos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}


// --- PuzzleNotifier (Corregido) ---
class PuzzleNotifier extends StateNotifier<PuzzleState> {
  // El constructor ya no necesita 'ref'
  PuzzleNotifier(
    Map<String, dynamic> challengeContent,
    int challengeId,
    int nivelId, // ← ¡AÑADIDO!
  ) : super(const PuzzleState()) {
    _loadChallenge(challengeContent, challengeId, nivelId); // ← ¡MODIFICADO!
  }

  // Lógica de carga (con duplicados y campos de estado)
  void _loadChallenge(Map<String, dynamic> challengeContent, int challengeId, int nivelId) { // ← ¡MODIFICADO!
    try {
      final challenge = PuzzleChallengeModel.fromJson(challengeContent);

      final Map<String, PuzzleOption?> initialBlanks = {};
      for (var line in challenge.lines) {
        if (line is BlankLine) {
          initialBlanks[line.id] = null;
        }
      }

      // --- ¡LÓGICA DE DUPLICADOS CORREGIDA! ---
      final List<PuzzleOption> bankOptions = [];
      
      // 1. Añadir todas las opciones correctas (con duplicados)
      for (var line in challenge.lines) {
        if (line is BlankLine) {
          final templateOption = challenge.options.firstWhere(
            (opt) => opt.id == line.correctOptionId,
            orElse: () => throw Exception("Opción correcta '${line.correctOptionId}' no encontrada"),
          );
          
          bankOptions.add(PuzzleOption(
            id: templateOption.id,
            text: templateOption.text,
            uniqueId: UniqueKey().toString(), // ¡ID único!
          ));
        }
      }

      // 2. Añadir las opciones "distractoras"
      final correctIds = bankOptions.map((opt) => opt.id).toSet();
      
      for (var templateOption in challenge.options) {
        if (!correctIds.contains(templateOption.id)) {
           bankOptions.add(PuzzleOption(
            id: templateOption.id,
            text: templateOption.text,
            uniqueId: UniqueKey().toString(), // ¡ID único!
          ));
        }
      }

      bankOptions.shuffle();
      // --- FIN LÓGICA DE DUPLICADOS ---

      state = state.copyWith(
        challenge: challenge,
        filledBlanks: initialBlanks,
        availableOptions: bankOptions,
        status: PuzzleStatus.playing,
        challengeId: challengeId,
        nivelId: nivelId, // ← ¡AÑADIDO!
        recursos: challenge.recursos,
        isLoading: false, // <-- Corregido
        error: null,
      );
    } catch (e) {
      debugPrint('Error al cargar reto de puzzle: $e');
      state = state.copyWith(
        isLoading: false,
        error: "Error al parsear el reto: $e", // <-- Corregido
      );
    }
  }

  // Lógica de checkSolution (simple)
  void checkSolution() {
    if (state.challenge == null) return;
    
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

    if (isCorrect) {
      state = state.copyWith(status: PuzzleStatus.correct);
    } else {
      state = state.copyWith(status: PuzzleStatus.incorrect);
    }
  }

  // --- ¡¡AQUÍ ESTÁ LA CORRECCIÓN DEL BUG!! ---
  
  void onOptionDroppedOnBlank(String blankId, PuzzleOption option) {
    // 1. Buscar si la opción que se está moviendo ya estaba en otro blank
    String? sourceBlankId;
    for (var entry in state.filledBlanks.entries) {
      if (entry.value?.uniqueId == option.uniqueId) {
        sourceBlankId = entry.key;
        break;
      }
    }

    // CASO ESPECIAL: Soltar en el mismo blank (no hacer nada)
    if (sourceBlankId != null && sourceBlankId == blankId) {
      // No hacer nada, el chip ya está en su lugar
      return;
    }

    // 2. Mira si ya hay una ficha en el hueco destino
    final PuzzleOption? existingOption = state.filledBlanks[blankId];

    // 3. Prepara el nuevo mapa de blanks y la lista de opciones
    Map<String, PuzzleOption?> newFilledBlanks = {...state.filledBlanks};
    List<PuzzleOption> newAvailableOptions = [...state.availableOptions];

    // 4. LÓGICA DE INTERCAMBIO O DEVOLUCIÓN
    if (sourceBlankId != null) {
      // La opción viene de otro blank (ya verificamos que sourceBlankId != blankId)
      if (existingOption != null) {
        // CASO 1: Intercambio entre dos blanks
        // Coloca la opción que estaba en el destino en el origen
        newFilledBlanks[sourceBlankId] = existingOption;
        // Y la opción que viene en el destino
        newFilledBlanks[blankId] = option;
      } else {
        // CASO 2: Mover de un blank a un blank vacío
        newFilledBlanks[sourceBlankId] = null;
        newFilledBlanks[blankId] = option;
      }
    } else {
      // La opción viene del banco de opciones
      // Eliminamos la opción del banco
      newAvailableOptions = newAvailableOptions
          .where((o) => o.uniqueId != option.uniqueId)
          .toList();
      
      if (existingOption != null) {
        // CASO 3: Viene del banco y hay una ficha en el destino
        // Devolvemos la ficha que estaba en el destino al banco
        newAvailableOptions.add(existingOption);
        newAvailableOptions.shuffle(); // (Opcional)
      }
      
      // Colocamos la nueva opción en el blank
      newFilledBlanks[blankId] = option;
    }

    // 5. Actualiza el estado
    state = state.copyWith(
      filledBlanks: newFilledBlanks,
      availableOptions: newAvailableOptions,
      status: PuzzleStatus.playing,
    );
  }

  // --- FIN DE LA CORRECCIÓN ---

  void onOptionDroppedOnBank(PuzzleOption option) {
    String? blankIdToRemove;
    for (var entry in state.filledBlanks.entries) {
      if (entry.value?.uniqueId == option.uniqueId) {
        blankIdToRemove = entry.key;
        break;
      }
    }

    if (blankIdToRemove != null) {
      // Si la opción estaba en un hueco, la devolvemos al banco
      state = state.copyWith(
        filledBlanks: {...state.filledBlanks, blankIdToRemove: null},
        availableOptions: [...state.availableOptions, option]..shuffle(),
        status: PuzzleStatus.playing, // Resetea el estado a "jugando"
      );
    }
  }

  void resetPuzzle() {
     if (state.challenge == null) return;
     // Recarga el reto con la lógica de duplicados
     _loadChallenge(
       {}, // Esto sigue estando mal si el JSON no está guardado,
          // pero es la lógica que tenías.
       state.challengeId,
       state.nivelId, // ← ¡AÑADIDO!
     );
  }
}