import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

final puzzleProvider =
    StateNotifierProvider.autoDispose<PuzzleNotifier, PuzzleState>((ref) {
      return PuzzleNotifier();
    });

enum PuzzleStatus { playing, correct, incorrect }

@immutable
class PuzzleState {
  final PuzzleChallengeModel? challenge;
  final Map<String, PuzzleOption?> filledBlanks;
  final List<PuzzleOption> availableOptions;
  final PuzzleStatus status;

  final int challengeId;
  final int nivelId;
  final List<RecursoModel> recursos;

  final bool isLoading;
  final String? error;

  const PuzzleState({
    this.challenge,
    this.filledBlanks = const {},
    this.availableOptions = const [],
    this.status = PuzzleStatus.playing,
    this.challengeId = 0,
    this.nivelId = 0,
    this.recursos = const [],
    this.isLoading = true,
    this.error,
  });

  PuzzleState copyWith({
    PuzzleChallengeModel? challenge,
    Map<String, PuzzleOption?>? filledBlanks,
    List<PuzzleOption>? availableOptions,
    PuzzleStatus? status,
    int? challengeId,
    int? nivelId,
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
      nivelId: nivelId ?? this.nivelId,
      recursos: recursos ?? this.recursos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier([
    Map<String, dynamic>? challengeContent,
    int challengeId = 0,
    int nivelId = 0,
  ]) : super(const PuzzleState(isLoading: true)) {
    if (challengeContent != null) {
      _loadChallenge(challengeContent, challengeId, nivelId);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void _loadChallenge(
    Map<String, dynamic> challengeContent,
    int challengeId,
    int nivelId,
  ) {
    try {
      final challenge = PuzzleChallengeModel.fromJson(challengeContent);
      _initializeStateFromModel(challenge, challengeId, nivelId);
    } catch (e) {
      debugPrint('Error al cargar reto de puzzle: $e');
      state = state.copyWith(
        isLoading: false,
        error: "Error al parsear el reto: $e",
      );
    }
  }

  void loadChallengeFromModel(PuzzleChallengeModel challenge) {
    _initializeStateFromModel(challenge, 0, 0);
  }

  void _initializeStateFromModel(
    PuzzleChallengeModel challenge,
    int challengeId,
    int nivelId,
  ) {
    final Map<String, PuzzleOption?> initialBlanks = {};
    for (var line in challenge.lines) {
      if (line is BlankLine) {
        initialBlanks[line.id] = null;
      }
    }

    final List<PuzzleOption> bankOptions = [];

    for (var line in challenge.lines) {
      if (line is BlankLine) {
        final templateOption = challenge.options.firstWhere(
          (opt) => opt.id == line.correctOptionId,
          orElse: () => throw Exception(
            "Opción correcta '${line.correctOptionId}' no encontrada",
          ),
        );

        bankOptions.add(
          PuzzleOption(
            id: templateOption.id,
            text: templateOption.text,
            uniqueId: UniqueKey().toString(),
          ),
        );
      }
    }

    final correctIds = bankOptions.map((opt) => opt.id).toSet();
    for (var templateOption in challenge.options) {
      if (!correctIds.contains(templateOption.id)) {
        bankOptions.add(
          PuzzleOption(
            id: templateOption.id,
            text: templateOption.text,
            uniqueId: UniqueKey().toString(),
          ),
        );
      }
    }

    bankOptions.shuffle();

    state = state.copyWith(
      challenge: challenge,
      filledBlanks: initialBlanks,
      availableOptions: bankOptions,
      status: PuzzleStatus.playing,
      challengeId: challengeId,
      nivelId: nivelId,
      recursos: challenge.recursos,
      isLoading: false,
      error: null,
    );
  }

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

  void onOptionDroppedOnBlank(String blankId, PuzzleOption option) {
    String? sourceBlankId;
    for (var entry in state.filledBlanks.entries) {
      if (entry.value?.uniqueId == option.uniqueId) {
        sourceBlankId = entry.key;
        break;
      }
    }

    if (sourceBlankId != null && sourceBlankId == blankId) return;

    final PuzzleOption? existingOption = state.filledBlanks[blankId];
    Map<String, PuzzleOption?> newFilledBlanks = {...state.filledBlanks};
    List<PuzzleOption> newAvailableOptions = [...state.availableOptions];

    if (sourceBlankId != null) {
      if (existingOption != null) {
        newFilledBlanks[sourceBlankId] = existingOption;
        newFilledBlanks[blankId] = option;
      } else {
        newFilledBlanks[sourceBlankId] = null;
        newFilledBlanks[blankId] = option;
      }
    } else {
      newAvailableOptions = newAvailableOptions
          .where((o) => o.uniqueId != option.uniqueId)
          .toList();

      if (existingOption != null) {
        newAvailableOptions.add(existingOption);
      }

      newFilledBlanks[blankId] = option;
    }

    state = state.copyWith(
      filledBlanks: newFilledBlanks,
      availableOptions: newAvailableOptions,
      status: PuzzleStatus.playing,
    );
  }

  void onOptionDroppedOnBank(PuzzleOption option) {
    String? blankIdToRemove;
    for (var entry in state.filledBlanks.entries) {
      if (entry.value?.uniqueId == option.uniqueId) {
        blankIdToRemove = entry.key;
        break;
      }
    }

    if (blankIdToRemove != null) {
      state = state.copyWith(
        filledBlanks: {...state.filledBlanks, blankIdToRemove: null},
        availableOptions: [...state.availableOptions, option]..shuffle(),
        status: PuzzleStatus.playing,
      );
    }
  }

  void resetPuzzle() {
    if (state.challenge == null) return;

    _initializeStateFromModel(
      state.challenge!,
      state.challengeId,
      state.nivelId,
    );
  }
}
